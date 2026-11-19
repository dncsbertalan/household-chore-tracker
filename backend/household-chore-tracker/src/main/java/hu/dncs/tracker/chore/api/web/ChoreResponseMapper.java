package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.chore.application.model.ChoreDetails;
import hu.dncs.tracker.chore.application.model.CreatedChore;
import hu.dncs.tracker.household.api.web.response.HouseholdMemberResponse;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import hu.dncs.tracker.identity.api.UserDirectory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
class ChoreResponseMapper {
    private final HouseholdMemberRepository members;
    private final UserDirectory users;

    ChoreResponse from(CreatedChore chore) { return enrich(List.of(ChoreResponse.from(chore))).getFirst(); }
    ChoreResponse from(ChoreDetails chore) { return enrich(List.of(ChoreResponse.from(chore))).getFirst(); }
    List<ChoreResponse> from(List<CreatedChore> chores) {
        return enrich(chores.stream().map(ChoreResponse::from).toList());
    }

    private List<ChoreResponse> enrich(List<ChoreResponse> chores) {
        var ids = chores.stream().flatMap(c -> c.assignedMemberIds().stream()).distinct().toList();
        if (ids.isEmpty()) return chores;
        var memberships = members.findAllById(ids);
        var profiles = users.findUserInfoByIds(memberships.stream().map(m -> m.getUserId()).distinct().toList());
        var byId = memberships.stream().map(m -> HouseholdMemberResponse.from(m, profiles.get(m.getUserId())))
                .collect(Collectors.toMap(HouseholdMemberResponse::householdMemberId, Function.identity()));
        return chores.stream().map(c -> c.withAssignedMembers(c.assignedMemberIds().stream()
                .map(byId::get).filter(java.util.Objects::nonNull).toList())).toList();
    }
}
