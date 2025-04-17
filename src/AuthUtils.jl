# src/AuthUtils.jl
module AuthUtils

using Genie.Sessions
using Genie.Router
#using GenieAuthentication # Not strictly needed for this manual setup
using Argon2
# Use relative path assuming Database.jl is in the same directory (src)
using ..Database # Correct way to reference sibling module
using Logging

export hash_password, verify_password, login_user!, logout_user!, current_user_id, is_authenticated, authenticate_request!

const SESSION_KEY = :user_id

function hash_password(password::String) :: String
    # Hash the password using Argon2id (recommended)
    return Argon2.argon2id_hash(password)
end

function verify_password(hash::String, password::String) :: Bool
    try
        return Argon2.argon2id_verify(hash, password)
    catch ex
        # Argon2 might throw if the hash format is wrong etc.
        @error "Password verification error: $ex"
        return false
    end
end

function login_user!(session::Session, user_id::Int)
    # Regenerate session ID upon login for security (prevents session fixation)
    Sessions.regenerate_id(session)
    Sessions.set!(session, SESSION_KEY, user_id)
    @info "User $user_id logged in. New Session ID: $(session.id)"
end

function logout_user!(session::Session)
    user_id = current_user_id(session) # Get user ID before clearing
    if !isnothing(user_id)
        @info "User $user_id logging out. Session ID: $(session.id)"
    else
        @info "Logout requested for non-authenticated session. Session ID: $(session.id)"
    end
    # Clear specific key and regenerate ID to invalidate old session completely
    Sessions.unset!(session, SESSION_KEY)
    Sessions.regenerate_id(session)
end

function current_user_id(session::Session) :: Union{Int, Nothing}
    return Sessions.get(session, SESSION_KEY)
end

function is_authenticated(session::Session) :: Bool
    # Check if the key exists and potentially if the value is of the expected type
    return Sessions.isset(session, SESSION_KEY) && isa(Sessions.get(session, SESSION_KEY), Int)
end

# Middleware-like function to protect routes
# Returns true if authenticated, false otherwise. Handles redirect internally.
function authenticate_request!(session::Session; redirect_route::Symbol = :get_login) :: Bool
    if !is_authenticated(session)
        @warn "Unauthenticated access attempt to protected resource."
        # Use flash message for better UX after redirect
        Genie.Flash.flash("Please log in to access this page.")
        # Redirect to the specified login route name
        Router.redirect_to(redirect_route)
        return false # Indicate authentication failed & redirect was issued
    end
    return true # Indicate authentication succeeded
end

end # module AuthUtils