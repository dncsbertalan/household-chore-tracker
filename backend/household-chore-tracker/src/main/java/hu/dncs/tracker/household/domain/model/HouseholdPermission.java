package hu.dncs.tracker.household.domain.model;

public enum HouseholdPermission {
    /**
     * Delete the household.
     */
    HOUSEHOLD_DELETE,

    /**
     * View household members.
     */
    HOUSEHOLD_MEMBER_VIEW,
    /**
     * Invite users to the household.
     */
    HOUSEHOLD_MEMBER_INVITE,
    /**
     * Remove members from the household.
     */
    HOUSEHOLD_MEMBER_REMOVE,
    /**
     * Assign household roles to members.
     */
    HOUSEHOLD_MEMBER_ASSIGN_ROLE,

    /**
     * View household roles and their permissions.
     */
    HOUSEHOLD_ROLE_VIEW,
    /**
     * Create household roles and configure their permissions.
     */
    HOUSEHOLD_ROLE_CREATE,
    /**
     * Update household roles and their permissions.
     */
    HOUSEHOLD_ROLE_UPDATE,
    /**
     * Delete household roles.
     */
    HOUSEHOLD_ROLE_DELETE,

    /**
     * Create chores in the household.
     */
    CHORE_CREATE,
    /**
     * Edit chore details, schedules, and recurrence.
     */
    CHORE_UPDATE,
    /**
     * Delete chores in the household.
     */
    CHORE_DELETE,
    /**
     * Assign household members to chores.
     */
    CHORE_ASSIGN_MEMBER,
    /**
     * Mark chores assigned to the current member as completed.
     */
    CHORE_COMPLETE,
    /**
     * Reopen completed chores in the household.
     */
    CHORE_REOPEN,
    /**
     * Approve chore completions in the household.
     */
    CHORE_APPROVE_COMPLETION
}
