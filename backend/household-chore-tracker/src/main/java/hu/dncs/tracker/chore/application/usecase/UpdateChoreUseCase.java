package hu.dncs.tracker.chore.application.usecase;

import hu.dncs.tracker.chore.application.ChoreInputValidator;
import hu.dncs.tracker.chore.application.command.UpdateChoreCommand;
import hu.dncs.tracker.chore.application.exception.ChoreNotFoundException;
import hu.dncs.tracker.chore.application.exception.ChoreUpdateConflictException;
import hu.dncs.tracker.chore.application.model.ChoreDetails;
import hu.dncs.tracker.chore.application.model.CreatedChore;
import hu.dncs.tracker.chore.domain.model.ChoreConstraints;
import hu.dncs.tracker.chore.domain.model.ChoreCreationPattern;
import hu.dncs.tracker.chore.domain.model.ChoreOccurrence;
import hu.dncs.tracker.chore.domain.model.ChoreSchedule;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreOccurrenceRepository;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreRepository;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreScheduleRepository;
import hu.dncs.tracker.household.application.HouseholdAuthorizationService;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Objects;
import java.util.UUID;

import static hu.dncs.tracker.household.domain.model.HouseholdPermission.CHORE_ASSIGN_MEMBER;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.CHORE_UPDATE;

@Service
@RequiredArgsConstructor
public class UpdateChoreUseCase {
    private final ChoreRepository chores;
    private final ChoreScheduleRepository schedules;
    private final ChoreOccurrenceRepository occurrences;
    private final HouseholdMemberRepository members;
    private final HouseholdAuthorizationService authorization;
    private final ChoreInputValidator validator;
    private final GetChoreUseCase getChore;

    @Transactional
    public ChoreDetails execute(UUID id, UpdateChoreCommand command, UUID userId) {
        var chore = chores.findForUpdate(id).orElseThrow(ChoreNotFoundException::new);
        authorization.requirePermission(chore.getHouseholdId(), userId, CHORE_UPDATE);

        var actor = members.findByHousehold_HouseholdIdAndUserId(chore.getHouseholdId(), userId).orElseThrow().getHouseholdMemberId();
        var schedule = schedules.findByChoreId(id).orElse(null);
        var history = occurrences.findForUpdate(id);
        var current = history.isEmpty() ? null : history.getFirst();
        if (current != null && !current.isEditable()) {
            throw new ChoreUpdateConflictException("Completed or closed chore occurrences cannot be edited.");
        }
        if (!Objects.equals(chore.getVersion(), command.version())
                || !Objects.equals(schedule == null ? null : schedule.getVersion(), command.scheduleVersion())
                || !Objects.equals(current == null ? null : current.getChoreOccurrenceId(), command.occurrenceId())
                || !Objects.equals(current == null ? null : current.getVersion(), command.occurrenceVersion())) {
            throw new ChoreUpdateConflictException("This chore has changed. Reload it before editing.");
        }
        boolean hasOccurrence = current != null || command.pattern() != ChoreCreationPattern.ON_DEMAND;
        var scheduledAt = command.scheduledAt();
        if (current == null && command.pattern() == ChoreCreationPattern.FIXED && scheduledAt == null) {
            scheduledAt = command.startsAt();
        }
        validator.validate(chore.getHouseholdId(), command.title(), command.description(), command.pattern(),
                command.recurrenceUnit(), command.recurrenceInterval(), command.startsAt(), scheduledAt,
                command.dueAt(), command.timeZoneIdentifier(), command.assignedMemberIds(), command.requiredApprovalCount(), hasOccurrence);
        var assignedIds = new HashSet<>(command.assignedMemberIds());
        boolean assignmentsChanged = !chore.getAssignedMemberIds().equals(assignedIds);
        if (assignmentsChanged) {
            authorization.requirePermission(chore.getHouseholdId(), userId, CHORE_ASSIGN_MEMBER);
        }
        var title = ChoreConstraints.trimmedText(command.title());
        var trimmedDescription = ChoreConstraints.trimmedText(command.description());
        String description = trimmedDescription.isEmpty() ? null : trimmedDescription;
        boolean titleChanged = !Objects.equals(chore.getTitle(), title);
        boolean descriptionChanged = !Objects.equals(chore.getDescription(), description);
        boolean approvalsChanged = chore.getRequiredApprovalCount() != command.requiredApprovalCount();
        chore.update(title, description, command.assignedMemberIds(), command.requiredApprovalCount(), actor);
        if (command.pattern() == ChoreCreationPattern.ONCE) {
            if (schedule != null) {
                schedules.delete(schedule);
            }
            schedule = null;
        } else if (schedule == null) {
            schedule = schedules.save(new ChoreSchedule(UUID.randomUUID(), id, command.pattern().scheduleType(),
                    command.recurrenceUnit(), command.recurrenceInterval(), command.startsAt(), command.timeZoneIdentifier(), actor));
        } else {
            schedule.update(command.pattern().scheduleType(), command.recurrenceUnit(), command.recurrenceInterval(),
                    command.startsAt(), command.timeZoneIdentifier(), actor);
        }
        // Type changes retain the current occurrence and every historical snapshot.
        if (current != null) {
            current.update(titleChanged ? title : current.getTitle(),
                    descriptionChanged ? description : current.getDescription(),
                    assignmentsChanged ? assignedIds : current.getAssignedMemberIds(),
                    approvalsChanged ? command.requiredApprovalCount() : current.getRequiredApprovalCount(),
                    scheduledAt, command.dueAt(), actor);
        } else if (hasOccurrence) {
            current = occurrences.save(new ChoreOccurrence(UUID.randomUUID(), chore, scheduledAt, command.dueAt(), actor));
            history.addFirst(current);
        }
        chores.flush();
        chore.getAssignedMemberIds().size();
        history.forEach(o -> o.getAssignedMemberIds().size());
        return getChore.execute(id, userId);
    }
}
