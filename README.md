## Gitsome Elixir Phoenix AwesomeElixir repository parser
Elixir / Phoenix приложение которое парсит [AwesomeElixir Repository](https://github.com/h4cc/awesome-elixir) и выводит рядом с каждым репозиторием количество звезд и дату последнего коммита

#### [Quick Demo](https://miniature-loose-blowfish.gigalixirapp.com/)
****
### Установка
Процесс установки и запуска достаточно прост.
На компьютере должен быть установлен **Erlang и Elixir**

* Шаг 1 - склонировать репозиторий
``` 
git clone https://github.com/Bkndns/phoenix_gitsome.git
```
* Шаг 2 - установить все зависимости 
```
mix deps.get
```
* Шаг 3 - сгенерировать GitHub token. Токен можно получить на странице `GitHub > Settings > Personal access tokens `  или перейдя по [https://github.com/settings/tokens](https://github.com/settings/tokens) 
```
https://github.com/settings/tokens
```
* Шаг 4 - скопировать полученный GitHub token и вставить его в config/config.exs. Ключ потребуется, чтобы иметь возможность делать больше запросов к серверу Github. Пример
```
config :gitsome, :git_hub_key, "PUT_YOUR_GITHUB_TOCKEN_HERE" # GITHUB TOKEN
```
```
# config/config.exs
# Личный ключ доступа к GitHub
config :gitsome, :git_hub_key, "375cdb206cdd56392faa094cdf816ef9604bd777" # GITHUB TOKEN
```
* Шаг 5 - запустить phoenix endpoint командой `mix phx.server`
```
mix phx.server
или
iex -S mix phx.server
```
* Шаг 6 - Подождать 1 минуту. После запуска сервера, **автоматически** начнётся парсинг репозиториев и продлиться чуть больше 1 минуты"
  
После этого можно открыть страницу [`localhost:4000`](http://localhost:4000) в браузере.
```
http://localhost:4000
```

*На этом установка и запуск завершена.*

### Примечания

  * #### [Quick Demo](https://miniature-loose-blowfish.gigalixirapp.com/)
  * Эта сборка не использует *ecto && postgres*
  * Phoenix проект был создан с флагами (`--no-webpack, --no-ecto, --no-dashboard`)
  * Вместо базы данных используется *ETS*
  * Не плохо было бы использовать Postgres, но мне хотелось выложить демо куда-нибудь и я не знал будет ли поддерживаться Postgres. Поэтому храним данные в ETS
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
