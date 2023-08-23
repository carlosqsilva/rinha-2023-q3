### CRUD em Vlang e picoev [#rinha-backend-2023-q3](https://github.com/zanfranceschi/rinha-de-backend-2023-q3)

#### Tecnologias
- [Vlang](https://vlang.io/)
- picoev (V implementation of [picoev](https://github.com/kazuho/picoev))
- Postgress
- Docker / Docker compose
- Nginx

#### Rodando projeto

na raiz do projeto, execute:

```sh
docker compose up
```

#### Publicando container

```sh
docker buildx build --platform linux/amd64,linux/arm64 -t insalubre/rinhabackend:latest --push .
```
