# Programowanie Aplikacji w Chmurze Obliczeniowej

      Marek Prokopiuk
      grupa dziekańska: 6.7
      numer albumu: 097710
## Zadanie 1<br>Część dodatkowa.
<p align="justify">Przedstawione zostało rozwiązanie części dodatkowej zadania 1 w ramach laboratorium z przedmiotu Programowanie Aplikacji w Chmurze Obliczeniowej. Przed przystąpieniem do realizacji tej części ćwiczenia należało wykonać wszystkie punkty z części obowiązkowej. Zostały one zrealizowane i są dostępne na publicznym repozytorium <a href="https://github.com/MarekP21/pawcho_zadanie1">pawcho_zadanie1</a>. Część dodatkowa polegała na zbudowaniu obrazów kontenera z aplikacją opracowaną w części obowiązkowej, które będą pracowały na architekturach <i>linux/arm64</i> oraz <i>linux/amd64</i>. Obrazy te należało zbudować z wykorzystaniem sterownika <i>docker-container</i>. Trzeba było zmodyfikować utworzony w części obowiązkowej plik Dockerfile tak, aby wykorzystywał rozszerzony frontend, zawierał deklaracje wykorzystania cache i umożliwiał bezpośrednie wykorzystanie kodów aplikacji umieszczonych we własnym repozytorium publicznym na GitHub. Opracowane obrazy należało przesłać do swojego repozytorium na DockerHub. W tym sprawozdaniu zostało właśnie przedstawione zrealizowanie całej części dodatkowej zadania 1.</p>

---

### 1. Zmodyfikowanie pliku Dockerfile
<p align="justify">Najpierw należało dokonać odpowiednich modyfikacji w pliku Dockerfile, aby wykorzystywał rozszerzony frontend, zawierał deklaracje wykorzystania cache oraz umożliwiał bezpośrednie wykorzystanie kodów aplikacji umieszczonych na GitHub. Na początku każdego etapu budowania obrazu została dodana następująca dyrektywa</p>

      # syntax=docker/dockerfile:1.2

<p align="justify">Jest to deklaracja wykorzystania rozszerzonego frontendu Dockerfile. Wykorzystywana jest składnia Dockerfile w wersji 1.2, która umożliwia używanie eksperymentalnych funkcji, takich jak montowanie zasobów.</p>  
<p align="justify">W ramach kolejnych modyfikacji dodano poniższe instrukcje</p>  

      RUN apk add --update nodejs npm && rm -rf /var/cache/apk/* \
          && apk add --no-cache openssh-client git \
          && mkdir -p -m 0700 ~/.ssh \ 
          && ssh-keyscan github.com >> ~/.ssh/known_hosts \
          && eval $(ssh-agent)

<p align="justify">Te polecenia odpowiedzialne są za instalacje Node.js, menadżera pakietów npm, klienta SSH i Git, a także usunięcie niepotrzebnych plików cache. Skanowany jest klucz hosta GitHub i dodawany do pliku <i>known_hosts</i> w katalogu <i>.ssh</i>. Na koniec uruchamiany jest agent SSH.</p>   
<p align="justify">Kolejną dodaną instrukcją jest</p>

      RUN --mount=type=ssh git clone git@github.com:MarekP21/pawcho_zadanie1_dod.git && \
          mv /usr/app/pawcho_zadanie1_dod/server.js /usr/app/pawcho_zadanie1_dod/package.json /usr/app

<p align="justify">Odpowiedzialna jest ona za klonowanie repozytorium GitHub z kodem aplikacji, wykorzystując agenta SSH do uwierzytelnienia. Jednocześnie przenosi ona pliki <a href="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/server.js">server.js</a> i <a href="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/package.json">package.json</a> do katalogu roboczego <i>/usr/app</i>.</p>
<p align="justify">Ostatnią dokonaną modyfikacją jest wykorzystanie polecenia</p>

      RUN npm install --production \
          --mount=type=cache,target=/root/.npm

<p align="justify">Instrukcja <i>RUN npm install --production</i> instaluje zależności aplikacji Node.js. Dodatkowo, opcja <i>--mount=type=cache,target=/root/.npm</i> wykorzystuje dane z cache, przyspieszając proces budowania obrazu poprzez ponowne wykorzystanie już pobranych i zainstalowanych zależności. Przeprowadzone modyfikacje spowodowały, że nowy Dockerfile wykorzystuje rozszerzony frontend, kody aplikacji z repozytorium publicznego na GitHub oraz wykorzystuje odpowiednio dane cache w procesie budowania obrazu. Oprócz pliku Dockerfile w celu realizacji zadania potrzebne są podobnie jak w przypadku części obowiązkowej następujące pliki: </p>

  - <a href="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/server.js">server.js</a> z aplikacją serwera
  - <a href="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/nginx.conf">nginx.conf</a> z konfiguracją nginx
  - <a href="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/package.json">package.json</a> z odpowiednimi zależnościami
  - <a href="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/alpine-minirootfs-3.19.1-x86_64.tar">alpine-minirootfs-3.19.1-x86_64</a> z warstwą bazową obrazu
  
<p>Cała zawartość pliku <a href="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/Dockerfile">Dockerfile</a> wraz z potrzebnymi komentarzami została przedstawiona poniżej</p><br>

```diff
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
```

---

### 2. Utworzenie buildera i zbudowanie obrazu
<p align="justify">W celu wykorzystania sterownika <i>docker-container</i> do budowy obrazu kontenera należało najpierw utworzyć własny builder (tutaj o nazwie <i>zad1_dod</i>) z użyciem tego sterownika. Następnie ten utworzony i uruchomiony builder został ustawiony jako domyślny. Widać to na poniższych zrzutach ekranu.</p>
<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/utworzenie_buildera.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 1. Utworzenie buildera</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/uzycie_buildera_jako_default.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 2. Ustawienie utworzonego buildera jako domyślny</i>
</p>

<p align="justify">Po odpowiednim zmodyfikowaniu pliku Dockerfile i utworzeniu własnego buildera można było przystąpić do budowania obrazu kontenera z aplikacją opracowaną w części obowiązkowej realizowanego zadania, który będzie pracował na architekturach <i>linux/arm64</i> oraz <i>linux/amd64</i>. Wykorzystane zostało w tym celu następujące polecenie</p>

      docker buildx build \
          --ssh default=$SSH_AUTH_SOCK \
          --build-arg BASE_VERSION=ver1 \
          --platform linux/arm64,linux/amd64 \
          --cache-from=type=registry,ref=docker.io/marektelem12/zad1_dod:cache \
          --cache-to=type=registry,ref=docker.io/marektelem12/zad1_dod:cache \
          -t marektelem12/zad1_dod:v1 \
          --push \
          .

Polecenie to jest odpowiedzialne za:

  * --ssh default=$SSH_AUTH_SOCK: Konfiguruje połączenie SSH z użyciem aktualnego agenta SSH, co umożliwia uwierzytelnianie przy użyciu kluczy SSH.
  * --build-arg BASE_VERSION=ver1: Przekazuje argument budowania o nazwie BASE_VERSION z wartością "ver1" do Dockerfile.
  * --platform linux/arm64,linux/amd64: Określa platformy, dla których należy zbudować obraz - w tym przypadku dla architektur arm64 oraz amd64.
  * --cache-from=type=registry,ref=docker.io/marektelem12/zad1_dod:cache: Określa źródło, z którego należy pobrać dane z cache podczas procesu budowania obrazu. 
  * --cache-to=type=registry,ref=docker.io/marektelem12/zad1_dod:cache: Określa, gdzie należy zachować dane cache po zakończeniu procesu budowania obrazu.
  * -t marektelem12/zad1_dod:v1: Określa tag obrazu, który zostanie nadany po zakończeniu procesu budowania.
  * --push: Wskazuje, że po zakończeniu budowania obrazu należy przesłać go do zdalnego rejestru Docker, zgodnie z tagiem określonym w poprzedniej linii.
  * . : Określa bieżący katalog jako kontekst budowy, czyli miejsce, w którym znajduje się Dockerfile i wszystkie inne pliki potrzebne do budowy obrazu.
    
<p align="justify">Nowo powstały obraz został od razu przesłany na moje repozytorium na DockerHub. Przy pierwszej próbie zbudowania obrazu otrzymany został error informujący, że nie udało się zaimportować manifestu cache z określonego źródła.</p>

       => ERROR importing cache manifest from docker.io/marektelem12/zad1_dod:cache        0.9s

<p align="justify">Stało się tak dlatego, że dane źródło jeszcze nie istniało. Przy drugim budowaniu obrazu wszystko było już w porządku i dane mogły być pobierane z cache. Wykonanie wyżej opisanego polecenia oraz proces budowy obrazu widać na poniższych rysunkach.</p>
<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/budowanie_obrazu_vol1.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 3. Budowanie obrazu - część 1</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/budowanie_obrazu_vol2.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 4. Budowanie obrazu - część 2</i>
</p>
<p align="justify">Obraz został zbudowany poprawnie i znalazł się w odpowiednim repozytorium na DockerHub (Rys. 6). Następnie z wykorzystaniem dostępnego wraz z buildx polecenia "docker buildx imagetools inspect", służącego do wyświetlenia szczegółowych informacji o obrazie, potwierdzono, że zbudowany obraz pracuje na architekturach <i>linux/arm64</i> oraz <i>linux/amd64</i>. Rezultat wykonanego polecenia widać na poniższym zrzucie ekranu.</p>
<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/sprawdzenie_manifestu_obrazu.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 5. Sprawdzenie szczegółowych informacji o obrazie</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/widok_obrazu_w_dockerhub.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 6. Widok obrazu w repozytorium na DockerHub</i>
</p>

---

### 3. Stworzenie i uruchomienie kontenera
<p align="justify">W celu utworzenia kontenera na podstawie zbudowanego obrazu należało ten obraz najpierw pobrać z publicznego repozytorium na Dockerhub, w którym się on znajduje. Wykorzystano zatem polecenie</p>

       docker pull marektelem12/zad1_dod:v1

<p align="justify">Następnie z wykorzystaniem tego obrazu został stworzony i uruchomiony kontener z aplikacją serwera. W celu przetestowania działania tej aplikacji użyto polecenia <i>curl</i>, a także sprawdzono widok w przeglądarce. Wszystkie wyżej opisane działania zostały przedstawione na poniższych rysunkach.</p>
<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/pobranie_obrazu_z_dockerhuba.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 7. Pobranie obrazu z DockerHub</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/stworzenie_i_uruchomienie_kontenera.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 8. Stworzenie i uruchomienie kontenera</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1_dod/blob/main/screeny_dod/widok_w_przegladarce.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 9. Widok działającej aplikacji w przeglądarce</i>
</p>

---
