# Mojo + PgREST

This makes a proxy to PgREST using Mojolicious. This is an experimental
code more to be refactored as a plugin not an entire application

# Idea

Using pgrest we create an OpenAPI REST from database schema. As such we can use
Mojolicious::Plugin::OpenAPI to read it and re-create it directly from
Mojolicious. Doing so we are able to send the request to Mojo and proxy it to
OpenREST. This scenario maybe useful for many situations, including auth step.

# Bugs

Still work in progress

