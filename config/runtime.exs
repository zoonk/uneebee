import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/zoonk start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :zoonk, ZoonkWeb.Endpoint, server: true
end

# Remove the https:// from the beginning of the AWS_ENDPOINT_URL_S3
aws_endpoint_url = String.replace(System.get_env("AWS_ENDPOINT_URL_S3"), "https://", "")

if config_env() in [:prod, :dev] do
  # Cloudflare images
  config :zoonk, :cloudflare,
    account_id: System.get_env("CLOUDFLARE_ACCOUNT_ID"),
    api_token: System.get_env("CLOUDFLARE_API_TOKEN"),
    account_hash: System.get_env("CLOUDFLARE_ACCOUNT_HASH")

  # AWS configuration
  config :ex_aws,
    debug_requests: true,
    json_coded: Jason,
    access_key_id: {:system, "AWS_ACCESS_KEY_ID"},
    secret_access_key: {:system, "AWS_SECRET_ACCESS_KEY"}

  config :ex_aws, :s3,
    scheme: "https://",
    host: aws_endpoint_url,
    region: System.get_env("AWS_REGION")

  config :zoonk, :storage,
    bucket: System.get_env("AWS_BUCKET"),
    domain: System.get_env("AWS_CDN_URL")
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :zoonk, Zoonk.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    ssl: [cacerts: :public_key.cacerts_get()]

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :zoonk, ZoonkWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :zoonk, ZoonkWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
  host = System.get_env("PHX_HOST")
  port = String.to_integer(System.get_env("PORT") || "8080")

  config :zoonk, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :zoonk, ZoonkWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: :conn,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  ## Configuring the mailer
  config :zoonk, Zoonk.Mailer,
    adapter: Resend.Swoosh.Adapter,
    api_key: System.get_env("RESEND_API_KEY")

  # Sentry configuration
  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    environment_name: :prod,
    enable_source_code_context: true,
    root_source_code_paths: [File.cwd!()],
    tags: %{env: :prod}
end
