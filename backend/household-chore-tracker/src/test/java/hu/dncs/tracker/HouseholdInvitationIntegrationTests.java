package hu.dncs.tracker;

import hu.dncs.tracker.household.application.command.CreateHouseholdCommand;
import hu.dncs.tracker.household.application.command.CreateHouseholdRoleCommand;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import tools.jackson.databind.ObjectMapper;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, HouseholdInvitationIntegrationTests.TimeConfiguration.class})
class HouseholdInvitationIntegrationTests {
    private static final String INBOX = "/api/v1/household-invitations";
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired CreateHouseholdUseCase createHousehold;
    @Autowired TestClock clock;
    UUID inviter;
    UUID recipient;
    UUID outsider;
    UUID householdId;
    UUID adminRoleId;
    UUID memberRoleId;
    String recipientEmail;

    @BeforeEach
    void setUp() {
        clock.now = Instant.parse("2026-10-27T12:00:00Z");
        inviter = account();
        recipient = account();
        outsider = account();
        recipientEmail = users.findById(recipient).orElseThrow().getEmail();
        householdId = UUID.randomUUID();
        adminRoleId = UUID.randomUUID();
        memberRoleId = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(householdId, "Our home", "Shared chores",
                List.of(new CreateHouseholdRoleCommand(adminRoleId, "Administrator", Set.of(HouseholdPermission.HOUSEHOLD_MEMBER_INVITE)),
                        new CreateHouseholdRoleCommand(memberRoleId, "Member", Set.of(HouseholdPermission.CHORE_CREATE))),
                adminRoleId, UUID.randomUUID()), inviter);
    }

    @Test
    void createsNormalizedInvitationWithoutAddingMembership() throws Exception {
        var result = invite("  " + recipientEmail.toUpperCase() + "  ", memberRoleId);
        assertThat(result.getResponse().getStatus()).isEqualTo(201);
        jsonPath("$.email").value(recipientEmail).match(result);
        jsonPath("$.householdName").value("Our home").match(result);
        jsonPath("$.householdRoleId").value(memberRoleId.toString()).match(result);
        jsonPath("$.householdRoleName").value("Member").match(result);
        jsonPath("$.invitedByUserId").value(inviter.toString()).match(result);
        jsonPath("$.status").value("PENDING").match(result);
        jsonPath("$.expiresAt").value("2026-11-03T12:00:00Z").match(result);
        assertThat(result.getResponse().getHeader("Location")).isEqualTo(INBOX + "/" + id(result));
        assertThat(memberCount(recipient)).isZero();
    }

    @Test
    void recipientCanDiscoverAndAcceptWithTheInvitedRole() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        mvc.perform(auth(get(INBOX), recipient)).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].householdInvitationId").value(id.toString()));
        mvc.perform(auth(get(INBOX + "/" + id), recipient)).andExpect(status().isOk());

        var accepted = mutate(post(INBOX + "/" + id + "/accept"), recipient);
        assertThat(accepted.getResponse().getStatus()).isEqualTo(200);
        jsonPath("$.householdId").value(householdId.toString()).match(accepted);
        jsonPath("$.name").value("Our home").match(accepted);
        jsonPath("$.roles.length()").value(2).match(accepted);
        jsonPath("$.membership.userId").value(recipient.toString()).match(accepted);
        jsonPath("$.membership.householdRole.householdRoleId").value(memberRoleId.toString()).match(accepted);
        jsonPath("$.membership.householdRole.permissions[0].name").value("CHORE_CREATE").match(accepted);
        jsonPath("$.membership.joinedAt").exists().match(accepted);
        assertThat(memberCount(recipient)).isEqualTo(1);
        assertThat(storedStatus(id)).isEqualTo("ACCEPTED");
        mvc.perform(auth(get(INBOX), recipient)).andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void canInviteBeforeRegistrationAndTheNewAccountFindsItsInbox() throws Exception {
        var email = UUID.randomUUID() + "@example.com";
        var id = id(invite(email, memberRoleId));
        var newUser = users.saveAndFlush(new User(email, "New", "Member")).getId();
        mvc.perform(auth(get(INBOX), newUser)).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].householdInvitationId").value(id.toString()));
        assertThat(mutate(post(INBOX + "/" + id + "/accept"), newUser).getResponse().getStatus()).isEqualTo(200);
    }

    @Test
    void otherAccountsCannotSeeOrRespondToTheInvitation() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        mvc.perform(auth(get(INBOX), outsider)).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(auth(get(INBOX + "/" + id), outsider)).andExpect(status().isNotFound());
        for (var action : List.of("accept", "decline")) {
            assertThat(mutate(post(INBOX + "/" + id + "/" + action), outsider).getResponse().getStatus()).isEqualTo(404);
        }
        assertThat(storedStatus(id)).isEqualTo("PENDING");
        assertThat(memberCount(outsider)).isZero();
    }

    @Test
    void creationListingAndRevocationRequireTheInviteGrant() throws Exception {
        assertThat(mutate(post(invitePath()).contentType(APPLICATION_JSON).content(body(recipientEmail, memberRoleId)), outsider)
                .getResponse().getStatus()).isEqualTo(403);
        var id = id(invite(recipientEmail, memberRoleId));
        mvc.perform(auth(get(invitePath()), outsider)).andExpect(status().isForbidden());
        assertThat(mutate(delete(invitePath() + "/" + id), outsider).getResponse().getStatus()).isEqualTo(403);
        jdbc.update("DELETE FROM household_role_permission WHERE household_role_id = ?", adminRoleId);
        assertThat(invite(users.findById(outsider).orElseThrow().getEmail(), memberRoleId).getResponse().getStatus()).isEqualTo(403);
        assertThat(mutate(delete(invitePath() + "/" + id), inviter).getResponse().getStatus()).isEqualTo(403);
    }

    @Test
    void authenticationIsRequiredAndDeletedAccountsAreRejected() throws Exception {
        mvc.perform(get(INBOX)).andExpect(status().isUnauthorized());
        mvc.perform(post(invitePath()).header("Authorization", "Bearer invalid").contentType(APPLICATION_JSON)
                .content(body(recipientEmail, memberRoleId))).andExpect(status().isUnauthorized());
        mvc.perform(auth(get(INBOX), UUID.randomUUID())).andExpect(status().isUnauthorized());
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "not-an-email", "a@", " ", "missing"})
    void invalidEmailsAreRejected(String email) throws Exception {
        var payload = email.equals("missing") ? Map.of("householdRoleId", memberRoleId) : Map.of("email", email, "householdRoleId", memberRoleId);
        var result = mutate(post(invitePath()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(payload)), inviter);
        assertThat(result.getResponse().getStatus()).isEqualTo(400);
        assertThat(invitationCount()).isZero();
    }

    @Test
    void unknownMissingAndForeignRolesAreRejected() throws Exception {
        var otherHousehold = UUID.randomUUID();
        var foreignRole = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(otherHousehold, "Other", null,
                List.of(new CreateHouseholdRoleCommand(foreignRole, "Other member", Set.of())), foreignRole, UUID.randomUUID()), inviter);
        assertThat(invite(recipientEmail, foreignRole).getResponse().getStatus()).isEqualTo(400);
        assertThat(invite(recipientEmail, UUID.randomUUID()).getResponse().getStatus()).isEqualTo(400);
        assertThat(mutate(post(invitePath()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("email", recipientEmail))), inviter).getResponse().getStatus()).isEqualTo(400);
        assertThat(invitationCount()).isZero();
    }

    @Test
    void cannotInviteAnExistingMemberOrCreateAnotherPendingInvite() throws Exception {
        assertThat(invite(users.findById(inviter).orElseThrow().getEmail(), memberRoleId).getResponse().getStatus()).isEqualTo(409);
        invite(recipientEmail, memberRoleId);
        assertThat(invite(recipientEmail.toUpperCase(), adminRoleId).getResponse().getStatus()).isEqualTo(409);
        assertThat(invitationCount()).isEqualTo(1);
    }

    @Test
    void declineDoesNotJoinAndAllowsANewInvitation() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        var declined = mutate(post(INBOX + "/" + id + "/decline"), recipient);
        assertThat(declined.getResponse().getStatus()).isEqualTo(200);
        jsonPath("$.status").value("DECLINED").match(declined);
        assertThat(memberCount(recipient)).isZero();
        assertThat(mutate(post(INBOX + "/" + id + "/accept"), recipient).getResponse().getStatus()).isEqualTo(409);
        assertThat(invite(recipientEmail, memberRoleId).getResponse().getStatus()).isEqualTo(201);
    }

    @Test
    void revokePreventsAcceptanceAndAllowsANewInvitation() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        assertThat(mutate(delete(invitePath() + "/" + id), inviter).getResponse().getStatus()).isEqualTo(204);
        assertThat(storedStatus(id)).isEqualTo("REVOKED");
        assertThat(mutate(post(INBOX + "/" + id + "/accept"), recipient).getResponse().getStatus()).isEqualTo(409);
        assertThat(invite(recipientEmail, memberRoleId).getResponse().getStatus()).isEqualTo(201);
    }

    @Test
    void invitationIdCannotBeRevokedThroughAnotherHousehold() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        var otherHousehold = UUID.randomUUID();
        var role = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(otherHousehold, "Other", null,
                List.of(new CreateHouseholdRoleCommand(role, "Admin", Set.of(HouseholdPermission.HOUSEHOLD_MEMBER_INVITE))),
                role, UUID.randomUUID()), inviter);
        assertThat(mutate(delete("/api/v1/households/" + otherHousehold + "/invitations/" + id), inviter)
                .getResponse().getStatus()).isEqualTo(404);
        assertThat(storedStatus(id)).isEqualTo("PENDING");
    }

    @Test
    void expiresExactlyAtTheDeadlineAndCanBeReplaced() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        clock.now = clock.now.plus(Duration.ofDays(7));
        mvc.perform(auth(get(INBOX), recipient)).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(auth(get(INBOX + "/" + id), recipient)).andExpect(jsonPath("$.status").value("EXPIRED"));
        for (var action : List.of("accept", "decline")) {
            assertThat(mutate(post(INBOX + "/" + id + "/" + action), recipient).getResponse().getStatus()).isEqualTo(410);
        }
        assertThat(invite(recipientEmail, memberRoleId).getResponse().getStatus()).isEqualTo(201);
        assertThat(storedStatus(id)).isEqualTo("EXPIRED");
        assertThat(memberCount(recipient)).isZero();
    }

    @Test
    void inviterCanListPendingAndAnsweredInvitationsWithEffectiveExpiry() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        clock.now = clock.now.plus(Duration.ofDays(8));
        mvc.perform(auth(get(invitePath()), inviter)).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].householdInvitationId").value(id.toString()))
                .andExpect(jsonPath("$[0].status").value("EXPIRED"));
    }

    @Test
    void retriesReplayCreationAndAcceptanceWithoutDuplicateEffects() throws Exception {
        var createKey = UUID.randomUUID();
        var payload = body(recipientEmail, memberRoleId);
        var first = mutate(post(invitePath()).contentType(APPLICATION_JSON).content(payload), inviter, createKey);
        var replay = mutate(post(invitePath()).contentType(APPLICATION_JSON).content(payload), inviter, createKey);
        assertSameResponse(first, replay);
        var id = id(first);
        var acceptKey = UUID.randomUUID();
        var accepted = mutate(post(INBOX + "/" + id + "/accept"), recipient, acceptKey);
        assertSameResponse(accepted, mutate(post(INBOX + "/" + id + "/accept"), recipient, acceptKey));
        assertThat(mutate(post(INBOX + "/" + id + "/accept"), recipient).getResponse().getStatus()).isEqualTo(409);
        assertThat(invitationCount()).isEqualTo(1);
        assertThat(memberCount(recipient)).isEqualTo(1);
    }

    @Test
    void declineAndRevocationCanAlsoBeRetried() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        var declineKey = UUID.randomUUID();
        var declined = mutate(post(INBOX + "/" + id + "/decline"), recipient, declineKey);
        assertSameResponse(declined, mutate(post(INBOX + "/" + id + "/decline"), recipient, declineKey));
        var replacement = id(invite(recipientEmail, memberRoleId));
        var revokeKey = UUID.randomUUID();
        var revoked = mutate(delete(invitePath() + "/" + replacement), inviter, revokeKey);
        assertSameResponse(revoked, mutate(delete(invitePath() + "/" + replacement), inviter, revokeKey));
    }

    @Test
    void mutationRequiresAnIdempotencyKeyAndRejectsReusingItForAnotherPayload() throws Exception {
        mvc.perform(auth(post(invitePath()).contentType(APPLICATION_JSON).content(body(recipientEmail, memberRoleId)), inviter))
                .andExpect(status().isBadRequest());
        var key = UUID.randomUUID();
        mutate(post(invitePath()).contentType(APPLICATION_JSON).content(body(recipientEmail, memberRoleId)), inviter, key);
        assertThat(mutate(post(invitePath()).contentType(APPLICATION_JSON).content(body(recipientEmail, adminRoleId)), inviter, key)
                .getResponse().getStatus()).isEqualTo(409);
    }

    @Test
    void simultaneousInvitesWithDifferentKeysCreateOnePendingInvitation() throws Exception {
        var results = concurrently(() -> invite(recipientEmail, memberRoleId), () -> invite(recipientEmail, memberRoleId));
        assertThat(results).extracting(result -> result.getResponse().getStatus()).containsExactlyInAnyOrder(201, 409);
        assertThat(invitationCount()).isEqualTo(1);
    }

    @Test
    void simultaneousAcceptanceWithDifferentKeysCreatesOneMembership() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        var results = concurrently(() -> mutate(post(INBOX + "/" + id + "/accept"), recipient),
                () -> mutate(post(INBOX + "/" + id + "/accept"), recipient));
        assertThat(results).extracting(result -> result.getResponse().getStatus()).containsExactlyInAnyOrder(200, 409);
        assertThat(memberCount(recipient)).isEqualTo(1);
    }

    @Test
    void concurrentAcceptAndRevokeHaveOneWinner() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        var results = concurrently(() -> mutate(post(INBOX + "/" + id + "/accept"), recipient),
                () -> mutate(delete(invitePath() + "/" + id), inviter));
        var accepted = results.getFirst().getResponse().getStatus() == 200;
        assertThat(results.getFirst().getResponse().getStatus()).isEqualTo(accepted ? 200 : 409);
        assertThat(results.getLast().getResponse().getStatus()).isEqualTo(accepted ? 409 : 204);
        assertThat(memberCount(recipient)).isEqualTo(accepted ? 1 : 0);
        assertThat(storedStatus(id)).isEqualTo(accepted ? "ACCEPTED" : "REVOKED");
    }

    @Test
    void databaseRejectsAssigningAnInvitationToAForeignHouseholdRole() throws Exception {
        var id = id(invite(recipientEmail, memberRoleId));
        var otherHousehold = UUID.randomUUID();
        var foreignRole = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(otherHousehold, "Other", null,
                List.of(new CreateHouseholdRoleCommand(foreignRole, "Other member", Set.of())), foreignRole, UUID.randomUUID()), inviter);
        assertThatThrownBy(() -> jdbc.update("UPDATE household_invitation SET household_role_id = ? WHERE household_invitation_id = ?",
                foreignRole, id)).isInstanceOf(DataIntegrityViolationException.class);
    }

    private UUID account() {
        return users.saveAndFlush(new User(UUID.randomUUID() + "@example.com", "Test", "User")).getId();
    }

    private String invitePath() {
        return "/api/v1/households/" + householdId + "/invitations";
    }

    private String body(String email, UUID roleId) {
        return mapper.writeValueAsString(Map.of("email", email, "householdRoleId", roleId));
    }

    private MvcResult invite(String email, UUID roleId) throws Exception {
        return mutate(post(invitePath()).contentType(APPLICATION_JSON).content(body(email, roleId)), inviter);
    }

    private UUID id(MvcResult result) throws Exception {
        assertThat(result.getResponse().getStatus()).isEqualTo(201);
        return UUID.fromString(mapper.readTree(result.getResponse().getContentAsString()).get("householdInvitationId").asString());
    }

    private MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request, UUID userId) {
        return request.with(jwt().jwt(jwt -> jwt.subject(userId.toString())));
    }

    private MvcResult mutate(MockHttpServletRequestBuilder request, UUID userId) throws Exception {
        return mutate(request, userId, UUID.randomUUID());
    }

    private MvcResult mutate(MockHttpServletRequestBuilder request, UUID userId, UUID key) throws Exception {
        return mvc.perform(auth(request.header("Idempotency-Key", key), userId)).andReturn();
    }

    private int memberCount(UUID userId) {
        return jdbc.queryForObject("SELECT count(*) FROM household_member WHERE household_id = ? AND user_id = ?",
                Integer.class, householdId, userId);
    }

    private int invitationCount() {
        return jdbc.queryForObject("SELECT count(*) FROM household_invitation WHERE household_id = ?", Integer.class, householdId);
    }

    private String storedStatus(UUID id) {
        return jdbc.queryForObject("SELECT status FROM household_invitation WHERE household_invitation_id = ?", String.class, id);
    }

    private static void assertSameResponse(MvcResult first, MvcResult replay) {
        assertThat(replay.getResponse().getStatus()).isEqualTo(first.getResponse().getStatus());
        assertThat(replay.getResponse().getContentAsByteArray()).isEqualTo(first.getResponse().getContentAsByteArray());
        assertThat(replay.getResponse().getHeader("Location")).isEqualTo(first.getResponse().getHeader("Location"));
    }

    private static List<MvcResult> concurrently(Callable<MvcResult> first, Callable<MvcResult> second) throws Exception {
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var a = executor.submit(() -> { start.await(); return first.call(); });
            var b = executor.submit(() -> { start.await(); return second.call(); });
            start.countDown();
            return List.of(a.get(20, TimeUnit.SECONDS), b.get(20, TimeUnit.SECONDS));
        }
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class TimeConfiguration {
        @Bean @Primary TestClock invitationTestClock() { return new TestClock(); }
    }

    static class TestClock extends Clock {
        volatile Instant now = Instant.parse("2026-10-27T12:00:00Z");
        @Override public ZoneId getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(ZoneId zone) { return Clock.fixed(now, zone); }
        @Override public Instant instant() { return now; }
    }
}
