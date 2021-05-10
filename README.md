# Dudle

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Running in production
To set up on the server: 
- Clone this repository
- On the production machine go into assets and run: `npm install` and then `npm run deploy` (dunno why lol)
- Get your ssl keys, (whatever.crt, server.key) and set the environment variables:
  `DUDLE_SSL_KEY_PATH=/wherever/server.key` and `DUDLE_SSL_CERT_PATH=/wherever/whatever.crt`
- Set up your database, and export the environment variable:
  `DATABASE_URL=ecto://databaseusername:databasepass@localhost/dudle`
- Export the secret key to the variable:
  `SECRET_KEY_BASE=akwjdhawkjdhawkjhdkajwhd`
- Run `PORT=80 MIX_ENV=prod iex -S mix phx.server`

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
