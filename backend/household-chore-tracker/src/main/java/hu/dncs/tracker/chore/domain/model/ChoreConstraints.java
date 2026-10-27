package hu.dncs.tracker.chore.domain.model;

public final class ChoreConstraints {
    public static final int TITLE_MAX_LENGTH = 100;
    public static final int DESCRIPTION_MAX_LENGTH = 500;

    private ChoreConstraints() {}

    /** Match Swift's CharacterSet.whitespacesAndNewlines, including NBSP, NEL, and zero-width space. */
    public static String trimmedText(String value) {
        if (value == null) return "";
        int start = 0;
        int end = value.length();
        while (start < end && isWhitespace(value.charAt(start))) start++;
        while (end > start && isWhitespace(value.charAt(end - 1))) end--;
        return value.substring(start, end);
    }

    private static boolean isWhitespace(char value) {
        return (value >= '\t' && value <= '\r') || Character.isSpaceChar(value)
                || value == '\u0085' || value == '\u200B';
    }
}
