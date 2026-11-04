package hu.dncs.tracker;

import hu.dncs.tracker.chore.api.web.request.UpdateChoreRequest;
import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.application.usecase.CreateChoreUseCase;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.chore.infrastructure.persistence.*;
import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import tools.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.*;
import java.util.stream.Stream;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class ChoreEditingIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired CreateHouseholdUseCase createHousehold;
    @Autowired CreateChoreUseCase createChore;
    @Autowired ChoreRepository chores;
    @Autowired ChoreOccurrenceRepository occurrences;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdRoleRepository roles;
    @Autowired HouseholdMemberRepository members;
    @Autowired JdbcTemplate jdbc;

    static Stream<Arguments> transitions() {
        return Arrays.stream(ChoreCreationPattern.values()).flatMap(from ->
                Arrays.stream(ChoreCreationPattern.values()).map(to -> Arguments.of(from, to)));
    }

    @ParameterizedTest
    @MethodSource("transitions")
    void editsEveryPatternAndTransitionWhileRetainingExistingOccurrenceIdentity(ChoreCreationPattern from, ChoreCreationPattern to) throws Exception {
        var f = fixture(from, CHORE_CREATE, CHORE_UPDATE, CHORE_ASSIGN_MEMBER);
        var original = detail(f);
        var request = request(original, to);
        var response = decode(update(f, request, UUID.randomUUID()).andExpect(status().isOk()).andReturn());
        assertThat(response.title()).isEqualTo("Changed chore");
        assertThat(response.description()).isEqualTo("Updated description");
        assertThat(response.version()).isGreaterThan(original.version());
        assertThat(response.choreId()).isEqualTo(original.choreId());
        assertThat(response.createdAt()).isEqualTo(original.createdAt());
        assertThat(response.createdByHouseholdMemberId()).isEqualTo(f.member);
        assertThat(response.updatedByHouseholdMemberId()).isEqualTo(f.member);
        if (to == ChoreCreationPattern.ONCE) assertThat(response.schedule()).isNull();
        else {
            assertThat(response.schedule().scheduleType()).isEqualTo(to.scheduleType());
            if (original.schedule() != null) assertThat(response.schedule().choreScheduleId()).isEqualTo(original.schedule().choreScheduleId());
            if (to == ChoreCreationPattern.FIXED) {
                // Retain the later instant during Budapest's repeated autumn hour.
                assertThat(response.schedule().startsAt()).isEqualTo(Instant.parse("2026-10-25T01:30:00Z"));
            }
        }
        if (original.occurrence() != null || to != ChoreCreationPattern.ON_DEMAND) {
            assertThat(response.occurrence()).isNotNull();
            assertThat(response.occurrences()).hasSize(1);
            assertThat(response.occurrence().title()).isEqualTo("Changed chore");
            assertThat(response.occurrence().assignedMemberIds()).containsExactly(f.member);
            assertThat(response.occurrence().requiredApprovalCount()).isEqualTo(1);
            assertThat(response.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.PENDING);
            if (original.occurrence() != null) assertThat(response.occurrence().choreOccurrenceId()).isEqualTo(original.occurrence().choreOccurrenceId());
        } else {
            assertThat(response.occurrence()).isNull();
            assertThat(response.occurrences()).isEmpty();
        }
        assertThat(detail(f).title()).isEqualTo(response.title());
    }

    @ParameterizedTest
    @EnumSource(value = ChoreOccurrenceStatus.class, names = {"COMPLETED", "AWAITING_APPROVAL", "SKIPPED", "CANCELLED"})
    void closedChoresRejectEvenAnEditorHoldingAnEarlierSnapshot(ChoreOccurrenceStatus status) throws Exception {
        var f = fixture(ChoreCreationPattern.FIXED, CHORE_CREATE, CHORE_UPDATE);
        var original = detail(f);
        jdbc.update("update chore_occurrence set occurrence_status = ?, version = version + 1 where chore_occurrence_id = ?",
                status.name(), original.occurrence().choreOccurrenceId());
        update(f, request(original, ChoreCreationPattern.FIXED), UUID.randomUUID())
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("chore_edit_conflict"));
        var unchanged = detail(f);
        assertThat(unchanged.title()).isEqualTo(original.title());
        assertThat(unchanged.version()).isEqualTo(original.version());
        assertThat(unchanged.occurrence().occurrenceStatus()).isEqualTo(status);
    }

    @Test
    void completedHistoricalOccurrencesStayUnchangedWhenTheNewCurrentOccurrenceIsEdited() throws Exception {
        var f = fixture(ChoreCreationPattern.FIXED, CHORE_CREATE, CHORE_UPDATE);
        var original = detail(f);
        var oldId = original.occurrence().choreOccurrenceId();
        jdbc.update("update chore_occurrence set occurrence_status='COMPLETED', created_at=created_at - interval '1 day' where chore_occurrence_id=?", oldId);
        var next = occurrences.saveAndFlush(new ChoreOccurrence(UUID.randomUUID(), chores.findVisible(f.user, null).stream().filter(c -> c.getChoreId().equals(f.id)).findFirst().orElseThrow(),
                Instant.parse("2026-12-02T12:00:00Z"), null, f.member));
        var current = detail(f);
        assertThat(current.occurrence().choreOccurrenceId()).isEqualTo(next.getChoreOccurrenceId());
        var changed = decode(update(f, request(current, ChoreCreationPattern.ON_DEMAND), UUID.randomUUID()).andExpect(status().isOk()).andReturn());
        assertThat(changed.occurrences()).hasSize(2);
        var historical = changed.occurrences().stream().filter(o -> o.choreOccurrenceId().equals(oldId)).findFirst().orElseThrow();
        assertThat(historical.title()).isEqualTo(original.occurrence().title());
        assertThat(historical.occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.COMPLETED);
        assertThat(historical.version()).isEqualTo(original.occurrence().version());
        assertThat(changed.occurrence().title()).isEqualTo("Changed chore");
    }

    @Test
    void staleVersionsAndNewCurrentOccurrencesCannotBeOverwritten() throws Exception {
        var f = fixture(ChoreCreationPattern.ONCE, CHORE_CREATE, CHORE_UPDATE);
        var original = detail(f);
        var request = request(original, ChoreCreationPattern.ONCE);
        update(f, request, UUID.randomUUID()).andExpect(status().isOk());
        update(f, request, UUID.randomUUID()).andExpect(status().isConflict());
        var latest = detail(f);
        occurrences.saveAndFlush(new ChoreOccurrence(UUID.randomUUID(), chores.findVisible(f.user, null).stream().filter(c -> c.getChoreId().equals(f.id)).findFirst().orElseThrow(), null, null, f.member));
        update(f, request(latest, ChoreCreationPattern.ONCE), UUID.randomUUID()).andExpect(status().isConflict());
    }

    @Test
    void unchangedExplicitRetryReplaysSuccessWithoutApplyingTheEditTwice() throws Exception {
        var f = fixture(ChoreCreationPattern.AFTER_COMPLETION, CHORE_CREATE, CHORE_UPDATE);
        var request = request(detail(f), ChoreCreationPattern.AFTER_COMPLETION);
        var key = UUID.randomUUID();
        var first = decode(update(f, request, key).andExpect(status().isOk()).andReturn());
        var replay = decode(update(f, request, key).andExpect(status().isOk()).andReturn());
        assertThat(replay).isEqualTo(first);
        assertThat(detail(f).version()).isEqualTo(first.version());
    }

    @Test
    void viewingRequiresMembershipAndEditingRequiresItsOwnGrant() throws Exception {
        var f = fixture(ChoreCreationPattern.ONCE, CHORE_CREATE);
        var request = request(detail(f), ChoreCreationPattern.ONCE);
        mvc.perform(get(path(f))).andExpect(status().isUnauthorized());
        mvc.perform(get(path(f)).with(jwt().jwt(j -> j.subject(UUID.randomUUID().toString())))).andExpect(status().isForbidden());
        update(f, request, UUID.randomUUID()).andExpect(status().isForbidden());
    }

    @Test
    void changingAssigneesNeedsTheAssignmentGrant() throws Exception {
        var f = fixture(ChoreCreationPattern.ONCE, CHORE_CREATE, CHORE_UPDATE);
        var member = members.findById(f.member).orElseThrow();
        var role = roles.findById(member.getHouseholdRole().getHouseholdRoleId()).orElseThrow();
        var other = members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), households.findById(member.getHousehold().getHouseholdId()).orElseThrow(), UUID.randomUUID(), role));
        var payload = mapper.convertValue(request(detail(f), ChoreCreationPattern.ONCE), Map.class);
        payload.put("assignedMemberIds", List.of(other.getHouseholdMemberId()));
        mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))
                        .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(payload)))
                .andExpect(status().isForbidden());
        assertThat(detail(f).assignedMemberIds()).containsExactly(f.member);
    }

    @Test
    void invalidDatesAndForeignAssigneesRollbackTheWholeAggregate() throws Exception {
        var f = fixture(ChoreCreationPattern.ONCE, CHORE_CREATE, CHORE_UPDATE, CHORE_ASSIGN_MEMBER);
        var original = detail(f);
        var payload = mapper.convertValue(request(original, ChoreCreationPattern.ONCE), Map.class);
        payload.put("dueAt", "2020-01-01T00:00:00Z");
        mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))
                        .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(payload)))
                .andExpect(status().isBadRequest());
        payload.put("dueAt", null);
        payload.put("assignedMemberIds", List.of(UUID.randomUUID()));
        mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))
                        .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(payload)))
                .andExpect(status().isBadRequest());
        assertThat(detail(f)).isEqualTo(original);
    }

    @Test
    void changingTemplateTextDoesNotResetUnchangedOccurrenceOverrides() throws Exception {
        var f = fixture(ChoreCreationPattern.FIXED, CHORE_CREATE, CHORE_UPDATE);
        var original = detail(f);
        jdbc.update("update chore_occurrence set description='Occurrence notes', required_approval_count=0 where chore_occurrence_id=?",
                original.occurrence().choreOccurrenceId());
        jdbc.update("delete from chore_occurrence_assigned_member where chore_occurrence_id=?", original.occurrence().choreOccurrenceId());
        var payload = mapper.convertValue(request(detail(f), ChoreCreationPattern.FIXED), Map.class);
        payload.put("description", original.description());
        var result = decode(mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))
                .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(payload)))
                .andExpect(status().isOk()).andReturn());
        assertThat(result.occurrence().title()).isEqualTo("Changed chore");
        assertThat(result.occurrence().description()).isEqualTo("Occurrence notes");
        assertThat(result.occurrence().assignedMemberIds()).isEmpty();
        assertThat(result.occurrence().requiredApprovalCount()).isZero();
        assertThat(result.assignedMemberIds()).containsExactly(f.member);
    }

    @Test
    void firstFixedOccurrenceUsesTheRecurrenceAnchorWhenNoTimeIsSupplied() throws Exception {
        var f = fixture(ChoreCreationPattern.ON_DEMAND, CHORE_CREATE, CHORE_UPDATE);
        var payload = mapper.convertValue(request(detail(f), ChoreCreationPattern.FIXED), Map.class);
        payload.put("scheduledAt", null);
        payload.put("dueAt", null);
        var result = decode(mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))
                .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(payload)))
                .andExpect(status().isOk()).andReturn());
        assertThat(result.occurrence().scheduledAt()).isEqualTo(result.schedule().startsAt());
        assertThat(result.occurrences()).hasSize(1);
    }

    private org.springframework.test.web.servlet.ResultActions update(Fixture f, UpdateChoreRequest request, UUID key) throws Exception {
        return mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))
                .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(request)));
    }

    private UpdateChoreRequest request(ChoreResponse response, ChoreCreationPattern pattern) {
        boolean recurring = pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION;
        boolean hasOccurrence = response.occurrence() != null || pattern != ChoreCreationPattern.ON_DEMAND;
        return new UpdateChoreRequest(response.version(), response.schedule() == null ? null : response.schedule().version(),
                response.occurrence() == null ? null : response.occurrence().choreOccurrenceId(),
                response.occurrence() == null ? null : response.occurrence().version(), " Changed chore ", " Updated description ",
                pattern, recurring ? ChoreRecurrenceUnit.WEEK : null, recurring ? 2 : 1,
                pattern == ChoreCreationPattern.FIXED ? Instant.parse("2026-10-25T01:30:00Z") : null,
                hasOccurrence ? Instant.parse("2026-12-02T12:00:00Z") : null,
                hasOccurrence ? Instant.parse("2026-12-03T12:00:00Z") : null, "Europe/Budapest", response.assignedMemberIds(), 1);
    }

    private ChoreResponse detail(Fixture f) throws Exception {
        return decode(mvc.perform(get(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))).andExpect(status().isOk()).andReturn());
    }
    private ChoreResponse decode(MvcResult result) throws Exception { return mapper.readValue(result.getResponse().getContentAsString(), ChoreResponse.class); }
    private String path(Fixture f) { return "/api/v1/chores/" + f.id; }

    private Fixture fixture(ChoreCreationPattern pattern, HouseholdPermission... grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID() + "@test.invalid", "Edit", "Test")).getId();
        var household = UUID.randomUUID();
        var role = UUID.randomUUID();
        var member = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(household, "Home", null,
                List.of(new CreateHouseholdRoleCommand(role, "Member", Set.of(grants))), role, member), user);
        var id = UUID.randomUUID();
        boolean recurring = pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION;
        createChore.execute(new CreateChoreCommand(id, household, "Original chore", "Original description", pattern,
                recurring ? ChoreRecurrenceUnit.DAY : null, 1,
                pattern == ChoreCreationPattern.ON_DEMAND ? null : Instant.parse("2026-12-01T12:00:00Z"), null,
                "Europe/Budapest", List.of(member), 1, pattern == ChoreCreationPattern.ONCE ? null : UUID.randomUUID(),
                pattern == ChoreCreationPattern.ON_DEMAND ? null : UUID.randomUUID()), user);
        return new Fixture(user, member, id);
    }
    private record Fixture(UUID user, UUID member, UUID id) {}
}
