package hu.dncs.tracker.chore.application.usecase;

import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.application.exception.ChoreCreationConflictException;
import hu.dncs.tracker.chore.application.exception.InvalidChoreException;
import hu.dncs.tracker.chore.application.model.CreatedChore;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreOccurrenceRepository;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreRepository;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreScheduleRepository;
import hu.dncs.tracker.household.application.HouseholdAuthorizationService;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import lombok.RequiredArgsConstructor;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.annotation.Transactional;

import java.time.DateTimeException;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CreateChoreUseCase {
    private final HouseholdAuthorizationService householdAuthorizationService;
    private final HouseholdMemberRepository householdMemberRepository;
    private final ChoreRepository choreRepository;
    private final ChoreScheduleRepository choreScheduleRepository;
    private final ChoreOccurrenceRepository choreOccurrenceRepository;

    @Transactional
    public CreatedChore execute(CreateChoreCommand command, UUID authenticatedUserId) {
        householdAuthorizationService.requirePermission(command.householdId(), authenticatedUserId, HouseholdPermission.CHORE_CREATE);
        var actor = householdMemberRepository.findByHousehold_HouseholdIdAndUserId(command.householdId(), authenticatedUserId)
                .orElseThrow(() -> new AccessDeniedException("Household membership is required."));
        var actorMemberId = actor.getHouseholdMemberId();
        validate(command);
        if (choreRepository.existsById(command.choreId())
                || (command.choreScheduleId() != null && choreScheduleRepository.existsById(command.choreScheduleId()))
                || (command.choreOccurrenceId() != null && choreOccurrenceRepository.existsById(command.choreOccurrenceId()))) {
            throw new ChoreCreationConflictException();
        }
        var description = ChoreConstraints.trimmedText(command.description());
        try {
            var chore = choreRepository.saveAndFlush(new Chore(command.choreId(), command.householdId(),
                    ChoreConstraints.trimmedText(command.title()), description.isEmpty()
                    ? null
                    : description, authenticatedUserId, actorMemberId,
                    command.assignedMemberIds(), command.requiredApprovalCount()));
            ChoreSchedule schedule = null;
            if (command.pattern() != ChoreCreationPattern.ONCE) {
                schedule = choreScheduleRepository.saveAndFlush(new ChoreSchedule(command.choreScheduleId(), chore.getChoreId(),
                        command.pattern().scheduleType(), command.recurrenceUnit(),
                        command.recurrenceInterval(), command.scheduledAt(), command.timeZoneIdentifier(), actorMemberId));
            }
            ChoreOccurrence occurrence = null;
            if (command.pattern() != ChoreCreationPattern.ON_DEMAND) {
                occurrence = choreOccurrenceRepository.saveAndFlush(new ChoreOccurrence(command.choreOccurrenceId(), chore,
                        command.scheduledAt(), command.dueAt(), actorMemberId));
            }
            return new CreatedChore(chore, schedule, occurrence);
        } catch (DataIntegrityViolationException exception) {
            for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
                if (cause instanceof ConstraintViolationException violation
                        && Set.of("chore_pkey", "chore_schedule_pkey", "chore_occurrence_pkey",
                                  "pk_chore", "pk_chore_schedule", "pk_chore_occurrence")
                        .contains(violation.getConstraintName())) {
                    throw new ChoreCreationConflictException();
                }
            }
            throw exception;
        }
    }

    private void validate(CreateChoreCommand command) {
        var title = ChoreConstraints.trimmedText(command.title());
        if (title.isEmpty() || title.length() > ChoreConstraints.TITLE_MAX_LENGTH
                || ChoreConstraints.trimmedText(command.description()).length() > ChoreConstraints.DESCRIPTION_MAX_LENGTH) {
            throw new InvalidChoreException("A title of 1–100 characters and a description of at most 500 characters are required.");
        }
        try {
            if (command.timeZoneIdentifier() == null || command.timeZoneIdentifier().length() > 100) {
                throw new InvalidChoreException("A valid time zone is required.");
            }
            ZoneId.of(command.timeZoneIdentifier());
        } catch (DateTimeException exception) {
            throw new InvalidChoreException("A valid time zone is required.");
        }
        var pattern = command.pattern();
        if (pattern == null || command.recurrenceInterval() < 1
                || ((pattern == ChoreCreationPattern.ONCE) != (command.choreScheduleId() == null))
                || ((pattern == ChoreCreationPattern.ON_DEMAND) != (command.choreOccurrenceId() == null))) {
            throw new InvalidChoreException("Schedule and occurrence IDs must match the creation pattern.");
        }
        boolean recurring = pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION;
        if (recurring != (command.recurrenceUnit() != null)
                || (pattern == ChoreCreationPattern.FIXED && command.scheduledAt() == null)
                || (pattern == ChoreCreationPattern.ON_DEMAND && (command.scheduledAt() != null || command.dueAt() != null))
                || (command.scheduledAt() != null && command.dueAt() != null && command.dueAt().isBefore(command.scheduledAt()))) {
            throw new InvalidChoreException("Invalid chore schedule.");
        }
        if (command.assignedMemberIds() == null || command.assignedMemberIds().stream().anyMatch(Objects::isNull)
                || new HashSet<>(command.assignedMemberIds()).size() != command.assignedMemberIds().size()) {
            throw new InvalidChoreException("Assignee IDs must be unique household-member IDs.");
        }
        var householdMembers = householdMemberRepository.findAllByHousehold_HouseholdId(command.householdId());
        var memberIds = new HashSet<>(householdMembers.stream().map(HouseholdMember::getHouseholdMemberId).toList());
        if (!memberIds.containsAll(command.assignedMemberIds()) || command.requiredApprovalCount() < 0
                || command.requiredApprovalCount() > memberIds.size()) {
            throw new InvalidChoreException("Assignees and approval count must belong to the household.");
        }
    }
}
