package hu.dncs.tracker;

import hu.dncs.tracker.household.application.HouseholdRoleManagementService;
import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.application.usecase.DeleteHouseholdUseCase;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.household.api.web.request.*;
import hu.dncs.tracker.household.api.web.response.HouseholdResponse;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicReference;
import java.util.stream.Stream;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class HouseholdEditingIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CreateHouseholdUseCase createHousehold;
    @Autowired DeleteHouseholdUseCase deletion;
    @Autowired HouseholdRoleManagementService management;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdMemberRepository members;
    @Autowired HouseholdRoleRepository roles;
    @Autowired PermissionRepository permissions;
    @Autowired UserRepository users;
    @Autowired PlatformTransactionManager transactions;

    @Test void updateGrantAloneEditsOnlyDetailsAndReturnsOnlyVisibleRolesAndMembers() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_UPDATE));
        person(f, Set.of(CHORE_COMPLETE));
        var before = read(f);
        var other = fixture(EnumSet.allOf(HouseholdPermission.class));
        var updated = decode(update(f, f.user, "New home", "New description", before.version(), UUID.randomUUID())
                .andExpect(status().isOk()).andReturn());
        assertThat(updated.name()).isEqualTo("New home");
        assertThat(updated.description()).isEqualTo("New description");
        assertThat(updated.version()).isGreaterThan(before.version());
        assertThat(updated.householdId()).isEqualTo(before.householdId());
        assertThat(updated.createdByUserId()).isEqualTo(before.createdByUserId());
        assertThat(updated.createdAt()).isEqualTo(before.createdAt());
        assertThat(updated.roles()).isEqualTo(before.roles());
        assertThat(updated.members()).isEqualTo(before.members());
        assertThat(updated.roles()).hasSize(1);
        assertThat(updated.members()).hasSize(1);
        assertThat(read(other).name()).isEqualTo("Original home");
    }

    @Test void creatorRoleAdministrationAndDeletionNeverBypassTheSpecificEditGrant() throws Exception {
        var f = fixture(EnumSet.complementOf(EnumSet.of(HOUSEHOLD_UPDATE)));
        update(f, f.user, "Denied", null, 0L, UUID.randomUUID()).andExpect(status().isForbidden());
        var outsider = fixture(EnumSet.allOf(HouseholdPermission.class));
        update(f, outsider.user, "Foreign", null, 0L, UUID.randomUUID()).andExpect(status().isForbidden());
        mvc.perform(put(path(f)).with(csrf()).header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(new UpdateHouseholdRequest("Denied", null, 0L)))).andExpect(status().isUnauthorized());
        assertThat(read(f).name()).isEqualTo("Original home");
    }

    @Test void removedCreatorCannotEditWithTheirOldGrant() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        person(f, Set.of(HOUSEHOLD_ROLE_UPDATE));
        management.removeMember(f.home, f.member, 0L, f.user);
        update(f, f.user, "Removed", null, 0L, UUID.randomUUID()).andExpect(status().isForbidden());
        assertThat(households.findById(f.home).orElseThrow().getName()).isEqualTo("Original home");
    }

    @Test void existingRoleAdministratorCanGrantTheNewPermissionThroughRoleManagement() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_ROLE_UPDATE));
        update(f, f.user, "Denied first", null, 0L, UUID.randomUUID()).andExpect(status().isForbidden());
        assertThat(permissions.findByName(HOUSEHOLD_UPDATE)).isPresent();
        mvc.perform(get(path(f)+"/roles").with(jwt().jwt(j -> j.subject(f.user.toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.permissions[?(@.name == 'HOUSEHOLD_UPDATE')]").isNotEmpty());
        var request = put(path(f)+"/roles/"+f.role).with(jwt().jwt(j -> j.subject(f.user.toString())))
                .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(new UpdateHouseholdRoleRequest("Administrator", List.of(HOUSEHOLD_ROLE_UPDATE, HOUSEHOLD_UPDATE), 0L)));
        mvc.perform(request).andExpect(status().isOk());
        update(f, f.user, "Allowed now", "Details", 0L, UUID.randomUUID()).andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Allowed now"));
    }

    @Test void whitespaceIsNormalizedAndDescriptionCanBeClearedOrOmitted() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_UPDATE));
        var first = decode(update(f, f.user, "\u00a0\u200b New home \u0085", "\n First line\nSecond line \u00a0", 0L, UUID.randomUUID())
                .andExpect(status().isOk()).andReturn());
        assertThat(first.name()).isEqualTo("New home");
        assertThat(first.description()).isEqualTo("First line\nSecond line");
        var cleared = decode(update(f, f.user, "New home", "\u00a0 \n\u200b", first.version(), UUID.randomUUID())
                .andExpect(status().isOk()).andReturn());
        assertThat(cleared.description()).isNull();
        update(f, f.user, "Still home", null, cleared.version(), UUID.randomUUID()).andExpect(status().isOk())
                .andExpect(jsonPath("$.description").doesNotExist());
    }

    @Test void unicodeLimitsMatchClientUtf16Validation() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_UPDATE));
        update(f, f.user, "😀".repeat(50), "😀".repeat(250), 0L, UUID.randomUUID()).andExpect(status().isOk());
        assertThat(read(f).name()).hasSize(100);
        assertThat(read(f).description()).hasSize(500);
    }

    static Stream<Arguments> invalidDetails() {
        return Stream.of(Arguments.of("", null), Arguments.of(" \n\t", null), Arguments.of("\u00a0\u0085\u200b", null),
                Arguments.of("a".repeat(101), null), Arguments.of("😀".repeat(51), null),
                Arguments.of("Valid", "a".repeat(501)), Arguments.of("Valid", "😀".repeat(251)));
    }
    @ParameterizedTest @MethodSource("invalidDetails")
    void invalidInputNeverPartiallyChangesTheHousehold(String name, String description) throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_UPDATE)); var before = read(f);
        update(f, f.user, name, description, before.version(), UUID.randomUUID()).andExpect(status().isBadRequest());
        assertThat(read(f)).isEqualTo(before);
    }

    @Test void missingNameOrVersionAndNegativeVersionAreRejected() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_UPDATE));
        for (var body : List.of("{\"name\":null,\"version\":0}", "{\"name\":\"Valid\"}", "{\"name\":\"Valid\",\"version\":-1}")) {
            mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                    .contentType(APPLICATION_JSON).content(body)).andExpect(status().isBadRequest());
        }
        assertThat(read(f).version()).isZero();
    }

    @Test void staleEditorAndStaleDeletionCannotOverwriteTheSavedDetails() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        update(f, f.user, "Saved", "Saved description", 0L, UUID.randomUUID()).andExpect(status().isOk());
        update(f, f.user, "Stale", "Old description", 0L, UUID.randomUUID()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_edit_stale"));
        mvc.perform(delete(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .param("version", "0").param("confirmed", "true")).andExpect(status().isConflict());
        assertThat(read(f).name()).isEqualTo("Saved");
        assertThat(read(f).description()).isEqualTo("Saved description");
    }

    @Test void retryReplaysOneSaveAndDeletionRedactsItsSavedRepresentation() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class)); var key = UUID.randomUUID();
        var first = update(f, f.user, "Private name", "Private description", 0L, key).andExpect(status().isOk()).andReturn();
        var replay = update(f, f.user, "Private name", "Private description", 0L, key).andExpect(status().isOk()).andReturn();
        assertThat(replay.getResponse().getContentAsString()).isEqualTo(first.getResponse().getContentAsString());
        assertThat(read(f).version()).isEqualTo(1L);
        update(f, f.user, "Different body", null, 0L, key).andExpect(status().isConflict());
        mvc.perform(delete(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .param("version", "1").param("confirmed", "true")).andExpect(status().isNoContent());
        update(f, f.user, "Private name", "Private description", 0L, key).andExpect(status().isGone())
                .andExpect(jsonPath("$.code").value("household_deleted"));
    }

    @Test void concurrentEditsFromTheSameVersionHaveOnlyOneWinner() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_UPDATE));
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            var a = pool.submit(() -> { gate.await(); return update(f, f.user, "First", "A", 0L, UUID.randomUUID()).andReturn().getResponse().getStatus(); });
            var b = pool.submit(() -> { gate.await(); return update(f, f.user, "Second", "B", 0L, UUID.randomUUID()).andReturn().getResponse().getStatus(); });
            gate.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder(200, 409);
        }
        assertThat(read(f).version()).isEqualTo(1L);
        assertThat(read(f).name()).isIn("First", "Second");
    }

    @Test void editorWaitingForPermissionRevocationCannotUseTheOldGrant() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class)); var editor = person(f, Set.of(HOUSEHOLD_UPDATE));
        try (var pool = Executors.newSingleThreadExecutor()) {
            var pending = new AtomicReference<Future<Integer>>();
            new TransactionTemplate(transactions).execute(status -> {
                management.update(f.home, editor.getHouseholdRole().getHouseholdRoleId(),
                        new SaveHouseholdRoleCommand("Revoked", List.of(HOUSEHOLD_ROLE_VIEW), 0L), f.user);
                pending.set(pool.submit(() -> update(f, editor.getUserId(), "Denied", null, 0L, UUID.randomUUID()).andReturn().getResponse().getStatus()));
                assertThatThrownBy(() -> pending.get().get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                return null;
            });
            assertThat(pending.get().get(15, TimeUnit.SECONDS)).isEqualTo(403);
        }
        assertThat(read(f).name()).isEqualTo("Original home");
    }

    @Test void editorWaitingForDeletionCannotRestoreTheHousehold() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        try (var pool = Executors.newSingleThreadExecutor()) {
            var pending = new AtomicReference<Future<Integer>>();
            new TransactionTemplate(transactions).execute(status -> {
                deletion.execute(f.home, 0L, true, f.user);
                pending.set(pool.submit(() -> update(f, f.user, "Late", null, 0L, UUID.randomUUID()).andReturn().getResponse().getStatus()));
                assertThatThrownBy(() -> pending.get().get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                return null;
            });
            assertThat(pending.get().get(15, TimeUnit.SECONDS)).isEqualTo(404);
        }
        assertThat(households.existsById(f.home)).isFalse();
    }

    private ResultActions update(Fixture f, UUID user, String name, String description, Long version, UUID key) throws Exception {
        return mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(user.toString()))).header("Idempotency-Key", key)
                .contentType(APPLICATION_JSON).content(mapper.writeValueAsString(new UpdateHouseholdRequest(name, description, version))));
    }
    private HouseholdResponse read(Fixture f) throws Exception {
        return decode(mvc.perform(get(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))).andExpect(status().isOk()).andReturn());
    }
    private HouseholdResponse decode(MvcResult result) throws Exception { return mapper.readValue(result.getResponse().getContentAsString(), HouseholdResponse.class); }
    private Fixture fixture(Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Household", "Editor")).getId();
        var home = UUID.randomUUID(); var role = UUID.randomUUID(); var member = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(home, "Original home", "Original description",
                List.of(new CreateHouseholdRoleCommand(role, "Administrator", grants)), role, member), user);
        return new Fixture(user, home, role, member);
    }
    private HouseholdMember person(Fixture f, Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Other", "Member")).getId();
        var role = new HouseholdRole(UUID.randomUUID(), f.home, "Editor", false);
        grants.forEach(g -> role.getPermissions().add(permissions.findByName(g).orElseThrow())); roles.saveAndFlush(role);
        return members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), households.findById(f.home).orElseThrow(), user, role));
    }
    private String path(Fixture f) { return "/api/v1/households/"+f.home; }
    private record Fixture(UUID user, UUID home, UUID role, UUID member) {}
}
