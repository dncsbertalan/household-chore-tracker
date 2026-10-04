package hu.dncs.tracker.identity.infrastructure.security;

import hu.dncs.tracker.identity.infrastructure.persistence.PasswordCredentialRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AccountUserDetailsService implements UserDetailsService {

    private final PasswordCredentialRepository credentials;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        var credential = credentials.findByUserEmail(hu.dncs.tracker.identity.domain.model.User.normalizeEmail(username))
                .orElseThrow(() -> new UsernameNotFoundException("Invalid credentials."));
        // Household roles belong to memberships, not to a global registration role.
        return new User(credential.getUser().getEmail(), credential.getPasswordHash(), List.of());
    }
}
