# Deklaracja wykorzystania rozszerzonego frontendu Dockerfile
# syntax=docker/dockerfile:1.2

# Etap 1: Budowanie aplikacji Node.js
FROM scratch AS first_step

ADD alpine-minirootfs-3.19.1-x86_64.tar /

ARG BASE_VERSION
ENV APP_VERSION=${BASE_VERSION:-v1}

# Instalacja komponentów środowiska roboczego,
# Instalacja klienta SSH i Git,
# Utworzenie katalogu SSH dla kluczy,
# Skanowanie hosta GitHub'a i dodanie go do known_hosts
# Oraz uruchomienie agenta SSH
RUN apk add --update nodejs npm && rm -rf /var/cache/apk/* \
    && apk add --no-cache openssh-client git \
    && mkdir -p -m 0700 ~/.ssh \ 
    && ssh-keyscan github.com >> ~/.ssh/known_hosts \
    && eval $(ssh-agent)

WORKDIR /usr/app

# Klonowanie repozytorium GitHub z kodem aplikacji
RUN --mount=type=ssh git clone git@github.com:MarekP21/pawcho_zadanie1_dod.git && \
    mv /usr/app/pawcho_zadanie1_dod/server.js /usr/app/pawcho_zadanie1_dod/package.json /usr/app

# Instalacja zależności i wykorzystanie rozszerzonego 
# Frontendu - umożliwienie wykorzystania danych cache 
# W procesie budowania obrazu
RUN npm install --production \
    --mount=type=cache,target=/root/.npm

#-----------------------------------------------------------------------
# Ponowna deklaracja wykorzystania rozszerzonego frontendu
# syntax=docker/dockerfile:1.2

# ETAP 2 Tworzenie obrazu produkcyjnego
FROM nginx:alpine3.19 AS second_step

# Powtórzenie deklaracji zmiennej
ARG BASE_VERSION

# Instalacja curl do obsługi testów healthcheck
# oraz ponowne dodanie Node.js
RUN apk add --update curl && \
    apk add --update nodejs npm && \ 
    rm -rf /var/cache/apk/*

# Zdefiniowanie katalogu roboczego
WORKDIR /usr/app

# Kopiowanie konfiguracji serwera HTTP
COPY --from=first_step /usr/app /usr/share/nginx/html/

# Skopiowanie pliku konfiguracyjnego 
# nginx.conf do katalogu /etc/nginx/conf.d/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Deklaracja katalogu roboczego
WORKDIR /usr/share/nginx/html

# Zdefiniowanie zmiennej środowiskowej z wersją aplikacji
ENV APP_VERSION=${BASE_VERSION:-v1}

# Deklaracja portu aplikacji w kontenerze
EXPOSE 8080

# Monitorowanie dostepnosci serwera
HEALTHCHECK --interval=10s --timeout=1s \
    CMD curl -f http://localhost:8080/ || exit 1

# Zdefiniowanie metadanych o autorze Dockerfile
# imię i nazwisko studenta
LABEL author="Marek Prokopiuk"

# Deklaracja sposobu uruchomienia serwera
CMD ["sh", "-c", "npm start & nginx -g 'daemon off;'"]
#-----------------------------------------------------------------------