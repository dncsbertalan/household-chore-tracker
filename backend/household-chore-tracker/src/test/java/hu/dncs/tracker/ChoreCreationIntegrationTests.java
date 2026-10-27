package hu.dncs.tracker;

import hu.dncs.tracker.chore.domain.model.ChoreScheduleType;
import hu.dncs.tracker.chore.domain.model.ChoreRecurrenceUnit;
import hu.dncs.tracker.chore.domain.model.ChoreOccurrenceStatus;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreScheduleRepository;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreOccurrenceRepository;
import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import tools.jackson.databind.ObjectMapper;
import java.util.*;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class ChoreCreationIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired CreateHouseholdUseCase createHousehold;
    @Autowired ChoreScheduleRepository schedules;
    @Autowired ChoreOccurrenceRepository occurrences;
    UUID account;
    UUID householdId;
    UUID memberId;
    UUID roleId;

    @BeforeEach
    void setUp() {
        account = users.saveAndFlush(new User(UUID.randomUUID() + "@test.invalid", "Test", "User")).getId();
        householdId = UUID.randomUUID();
        roleId = UUID.randomUUID();
        memberId = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(householdId, "Home", null,
                List.of(new CreateHouseholdRoleCommand(roleId, "Member", Set.of(HouseholdPermission.CHORE_CREATE))),
                roleId, memberId), account);
    }

    @ParameterizedTest
    @ValueSource(strings = {"ONCE", "FIXED", "AFTER_COMPLETION", "ON_DEMAND"})
    void createsTheSameGraphAsTheFrontendForEveryPattern(String pattern) throws Exception {
        var request = request(pattern);
        var choreId = request.get("choreId");
        var result = send(account, UUID.randomUUID(), request);
        assertThat(result.getResponse().getStatus()).isEqualTo(201);
        jsonPath("$.title").value("Wash dishes").match(result);
        jsonPath("$.createdByUserId").value(account.toString()).match(result);
        jsonPath("$.createdByHouseholdMemberId").value(memberId.toString()).match(result);
        jsonPath("$.updatedByHouseholdMemberId").value(memberId.toString()).match(result);
        jsonPath("$.updatedAt").exists().match(result);
        jsonPath("$.assignedMemberIds[0]").value(memberId.toString()).match(result);
        jsonPath("$.requiredApprovalCount").value(1).match(result);
        if (!pattern.equals("ONCE")) {
            jsonPath("$.schedule.choreScheduleId").value(request.get("choreScheduleId").toString()).match(result);
            jsonPath("$.schedule.scheduleType").value(pattern).match(result);
            var persisted = schedules.findById((UUID) request.get("choreScheduleId")).orElseThrow();
            assertThat(persisted.getScheduleType()).isEqualTo(ChoreScheduleType.valueOf(pattern));
            assertThat(persisted.getRecurrenceUnit()).isEqualTo(pattern.equals("ON_DEMAND") ? null : ChoreRecurrenceUnit.DAY);
            assertThat(persisted.getCreatedByHouseholdMemberId()).isEqualTo(memberId);
            assertThat(persisted.getUpdatedByHouseholdMemberId()).isEqualTo(memberId);
            jsonPath("$.schedule.createdByHouseholdMemberId").value(memberId.toString()).match(result);
            jsonPath("$.schedule.updatedByHouseholdMemberId").value(memberId.toString()).match(result);
            jsonPath("$.schedule.createdAt").exists().match(result);
            jsonPath("$.schedule.updatedAt").exists().match(result);
        }
        if (!pattern.equals("ON_DEMAND")) {
            jsonPath("$.occurrence.choreOccurrenceId").value(request.get("choreOccurrenceId").toString()).match(result);
            jsonPath("$.occurrence.scheduledAt").value(request.get("scheduledAt")).match(result);
            jsonPath("$.occurrence.occurrenceStatus").value("PENDING").match(result);
            jsonPath("$.occurrence.createdByHouseholdMemberId").value(memberId.toString()).match(result);
            jsonPath("$.occurrence.updatedByHouseholdMemberId").value(memberId.toString()).match(result);
            jsonPath("$.occurrence.updatedAt").exists().match(result);
            assertThat(occurrences.findById((UUID) request.get("choreOccurrenceId")).orElseThrow().getOccurrenceStatus())
                    .isEqualTo(ChoreOccurrenceStatus.PENDING);
        }
        assertThat(jdbc.queryForObject("SELECT created_by_user_id FROM chore WHERE chore_id = ?", UUID.class, choreId)).isEqualTo(account);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM chore_schedule WHERE chore_id = ?", Integer.class, choreId))
                .isEqualTo(pattern.equals("ONCE") ? 0 : 1);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM chore_occurrence WHERE chore_id = ?", Integer.class, choreId))
                .isEqualTo(pattern.equals("ON_DEMAND") ? 0 : 1);
        if (!pattern.equals("ON_DEMAND")) {
            assertThat(jdbc.queryForObject("SELECT occurrence_status FROM chore_occurrence WHERE chore_id = ?", String.class, choreId)).isEqualTo("PENDING");
            assertThat(jdbc.queryForObject("SELECT count(*) FROM chore_occurrence_assigned_member WHERE chore_occurrence_id = ?", Integer.class,
                    request.get("choreOccurrenceId"))).isEqualTo(1);
        }
    }

    @Test
    void lostResponseReplaysExactlyWithoutCreatingMoreRecords() throws Exception {
        var request = request("FIXED");
        var key = UUID.randomUUID();
        var first = send(account, key, request);
        var second = send(account, key, request);
        assertThat(first.getResponse().getStatus()).isEqualTo(201);
        assertThat(second.getResponse().getContentAsByteArray()).isEqualTo(first.getResponse().getContentAsByteArray());
        assertThat(second.getResponse().getHeader("Location")).isEqualTo(first.getResponse().getHeader("Location"));
        assertThat(jdbc.queryForObject("SELECT count(*) FROM chore WHERE chore_id = ?", Integer.class, request.get("choreId"))).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM processed_request WHERE account_id = ?", Integer.class, account)).isEqualTo(1);
    }

    @ParameterizedTest
    @CsvSource({
            "2026-10-25T00:30:00Z, Europe/Budapest, 2026-10-25T02:30:00, 7200",
            "2026-10-25T01:30:00Z, Europe/Budapest, 2026-10-25T02:30:00, 3600",
            "2026-03-28T08:00:00Z, Europe/Budapest, 2026-03-28T09:00:00, 3600",
            "2026-07-01T07:00:00Z, Europe/Budapest, 2026-07-01T09:00:00, 7200",
            "2026-10-27T08:00:00Z, UTC+02:30, 2026-10-27T10:30:00, 9000",
            "2026-10-27T08:00:00Z, GMT-04:00, 2026-10-27T04:00:00, -14400",
            "2026-10-27T08:00:00Z, UTC+2, 2026-10-27T10:00:00, 7200",
            "2026-10-27T08:00:00Z, GMT+0200, 2026-10-27T10:00:00, 7200",
            "2026-10-27T08:00:00Z, +023015, 2026-10-27T10:30:15, 9015"
    })
    void scheduleStoresLocalTimeAndPreservesSelectedInstant(String start, String zone, String local, int offset) throws Exception {
        var request = request("FIXED");
        request.put("scheduledAt", start);
        request.put("timeZoneIdentifier", zone);
        request.remove("dueAt");
        var result = send(account, UUID.randomUUID(), request);
        assertThat(result.getResponse().getStatus()).isEqualTo(201);
        jsonPath("$.schedule.startsAt").value(start).match(result);
        jsonPath("$.occurrence.scheduledAt").value(start).match(result);
        var schedule = schedules.findById((UUID) request.get("choreScheduleId")).orElseThrow();
        assertThat(schedule.getStartsAt()).isEqualTo(LocalDateTime.parse(local));
        assertThat(schedule.getStartsAtOffsetSeconds()).isEqualTo(offset);
        assertThat(schedule.getStartsAtInstant()).isEqualTo(Instant.parse(start));
        assertThat(schedule.getZonedStartsAt().toInstant()).isEqualTo(Instant.parse(start));
    }

    @Test
    void recurringCalendarAnchorKeepsNineAmAcrossSpringDst() throws Exception {
        var request = request("FIXED");
        request.put("scheduledAt", "2026-03-28T08:00:00Z");
        request.remove("dueAt");
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(201);
        var anchor = schedules.findById((UUID) request.get("choreScheduleId")).orElseThrow().getZonedStartsAt();
        var next = anchor.plusDays(1);
        assertThat(next.getHour()).isEqualTo(9);
        assertThat(Duration.between(anchor.toInstant(), next.toInstant())).isEqualTo(Duration.ofHours(23));
    }

    @Test
    void consolidatedSchemaProtectsAuditIdsAndScheduleConfiguration() throws Exception {
        var request = request("FIXED");
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(201);
        assertThatThrownBy(() -> jdbc.update("UPDATE chore SET updated_by_household_member_id = ? WHERE chore_id = ?",
                UUID.randomUUID(), request.get("choreId"))).isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("UPDATE chore_schedule SET starts_at_offset_seconds = NULL WHERE chore_schedule_id = ?",
                request.get("choreScheduleId"))).isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("UPDATE chore_occurrence SET occurrence_status = 'UNKNOWN' WHERE chore_occurrence_id = ?",
                request.get("choreOccurrenceId"))).isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.queryForObject("SELECT updated_by_household_member_id FROM chore WHERE chore_id = ?",
                UUID.class, request.get("choreId"))).isEqualTo(memberId);
    }

    @Test
    void lowercaseRequestIsRejectedByTheUppercaseEnumContract() throws Exception {
        var request = request("FIXED");
        request.put("pattern", "fixed");
        request.put("recurrenceUnit", "day");
        var result = send(account, UUID.randomUUID(), request);
        assertThat(result.getResponse().getStatus()).isEqualTo(400);
        assertNoCreation(request);
    }

    @Test
    void deniedCreatorAndNonMemberCannotWriteChoresOrReceipts() throws Exception {
        jdbc.update("DELETE FROM household_role_permission WHERE household_role_id = ?", roleId);
        var request = request("FIXED");
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(403);
        var outsider = users.saveAndFlush(new User(UUID.randomUUID() + "@test.invalid", "Other", "User")).getId();
        assertThat(send(outsider, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(403);
        assertNoCreation(request);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM processed_request WHERE account_id = ?", Integer.class, account)).isZero();
    }

    @Test
    void permissionRevokedBeforeDeliveryIsRejectedAndCanBeRetriedAfterGranting() throws Exception {
        var request = request("ONCE");
        var key = UUID.randomUUID();
        jdbc.update("DELETE FROM household_role_permission WHERE household_role_id = ?", roleId);
        assertThat(send(account, key, request).getResponse().getStatus()).isEqualTo(403);
        assertNoCreation(request);
        jdbc.update("INSERT INTO household_role_permission SELECT ?, permission_id FROM permission WHERE name = 'CHORE_CREATE'", roleId);
        assertThat(send(account, key, request).getResponse().getStatus()).isEqualTo(201);
    }

    @Test
    void authenticatedPrincipalDeterminesCreatorEvenWhenBodyTriesToOverrideIt() throws Exception {
        var request = request("ONCE");
        request.put("createdByUserId", UUID.randomUUID());
        request.put("createdByHouseholdMemberId", UUID.randomUUID());
        request.put("updatedByHouseholdMemberId", UUID.randomUUID());
        var result = send(account, UUID.randomUUID(), request);
        assertThat(result.getResponse().getStatus()).isEqualTo(201);
        assertThat(jdbc.queryForObject("SELECT created_by_user_id FROM chore WHERE chore_id = ?", UUID.class, request.get("choreId"))).isEqualTo(account);
        assertThat(jdbc.queryForObject("SELECT created_by_household_member_id FROM chore WHERE chore_id = ?", UUID.class, request.get("choreId"))).isEqualTo(memberId);
        assertThat(jdbc.queryForObject("SELECT updated_by_household_member_id FROM chore WHERE chore_id = ?", UUID.class, request.get("choreId"))).isEqualTo(memberId);
    }

    @Test
    void validatesAssigneesAndApprovalCountsWithoutPartialWrites() throws Exception {
        for (var invalid : List.of(List.of(memberId, memberId), List.of(UUID.randomUUID()))) {
            var request = request("FIXED");
            request.put("assignedMemberIds", invalid);
            assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(400);
            assertNoCreation(request);
        }
        var request = request("FIXED");
        request.put("requiredApprovalCount", 2);
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(400);
        assertNoCreation(request);
    }

    @Test
    void rejectsInvalidSchedulesAndPatternIds() throws Exception {
        var invalidChanges = List.<Map<String, Object>>of(
                Map.of("timeZoneIdentifier", "Invalid/Timezone"), Map.of("recurrenceInterval", 0),
                Map.of("scheduledAt", "2026-10-28T10:00:00Z"), Map.of("recurrenceUnit", "invalid"));
        for (var change : invalidChanges) {
            var request = request("FIXED");
            request.putAll(change);
            assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(400);
            assertNoCreation(request);
        }
        for (String missing : List.of("scheduledAt", "choreScheduleId", "choreOccurrenceId", "recurrenceUnit")) {
            var request = request("FIXED");
            request.remove(missing);
            assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(400);
            assertNoCreation(request);
        }
        var request = request("ON_DEMAND");
        request.put("dueAt", "2026-10-28T09:00:00Z");
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(400);
        assertNoCreation(request);
    }

    @Test
    void rejectsOverlongUtf16DetailsAndNormalizesWhitespace() throws Exception {
        var request = request("ONCE");
        request.put("title", "😀".repeat(51));
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(400);
        assertNoCreation(request);
        request.put("title", "   \n  ");
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(400);
        request.put("title", "\u200B\u0085\u00A0Wash dishes\u00A0\u200B");
        request.put("description", "  ");
        var result = send(account, UUID.randomUUID(), request);
        assertThat(result.getResponse().getStatus()).isEqualTo(201);
        assertThat(jdbc.queryForObject("SELECT title FROM chore WHERE chore_id = ?", String.class, request.get("choreId"))).isEqualTo("Wash dishes");
        assertThat(jdbc.queryForObject("SELECT description FROM chore WHERE chore_id = ?", String.class, request.get("choreId"))).isNull();
    }

    @Test
    void existingIdsReturnConflictRatherThanOverwritingAnotherChore() throws Exception {
        var request = request("FIXED");
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(201);
        request.put("title", "Overwritten");
        assertThat(send(account, UUID.randomUUID(), request).getResponse().getStatus()).isEqualTo(409);
        assertThat(jdbc.queryForObject("SELECT title FROM chore WHERE chore_id = ?", String.class, request.get("choreId"))).isEqualTo("Wash dishes");
        var another = request("FIXED");
        another.put("choreScheduleId", request.get("choreScheduleId"));
        assertThat(send(account, UUID.randomUUID(), another).getResponse().getStatus()).isEqualTo(409);
        assertNoCreation(another);
    }

    @Test
    void requiresAuthenticationAndAnIdempotencyKey() throws Exception {
        var content = mapper.writeValueAsString(request("ONCE"));
        mvc.perform(post("/api/v1/chores").header("Authorization", "Bearer invalid")
                .contentType(APPLICATION_JSON).content(content)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/chores").with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                .contentType(APPLICATION_JSON).content(content)).andExpect(status().isBadRequest());
    }

    private Map<String, Object> request(String pattern) {
        var request = new LinkedHashMap<String, Object>();
        request.put("choreId", UUID.randomUUID());
        request.put("householdId", householdId);
        request.put("title", "Wash dishes");
        request.put("description", "After dinner");
        request.put("pattern", pattern);
        request.put("recurrenceInterval", 1);
        request.put("timeZoneIdentifier", "Europe/Budapest");
        request.put("assignedMemberIds", List.of(memberId));
        request.put("requiredApprovalCount", 1);
        if (!pattern.equals("ONCE")) request.put("choreScheduleId", UUID.randomUUID());
        if (!pattern.equals("ON_DEMAND")) {
            request.put("choreOccurrenceId", UUID.randomUUID());
            request.put("scheduledAt", "2026-10-27T08:00:00.125Z");
            request.put("dueAt", "2026-10-27T09:00:00Z");
        }
        if (pattern.equals("FIXED") || pattern.equals("AFTER_COMPLETION")) request.put("recurrenceUnit", "DAY");
        return request;
    }

    private MvcResult send(UUID user, UUID key, Map<String, Object> request) throws Exception {
        return mvc.perform(post("/api/v1/chores").with(jwt().jwt(jwt -> jwt.subject(user.toString())))
                .header("Idempotency-Key", key).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(request))).andReturn();
    }

    private void assertNoCreation(Map<String, Object> request) {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM chore WHERE chore_id = ?", Integer.class, request.get("choreId"))).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM chore_schedule WHERE chore_id = ?", Integer.class, request.get("choreId"))).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM chore_occurrence WHERE chore_id = ?", Integer.class, request.get("choreId"))).isZero();
    }
}
