<<<<<<< HEAD
Dokumentacja Projektu: Aplikacja Mobilna QuickNotes

Spis treści

1. Wprowadzenie	1
2. Cel Projektu	1
3. Architektura Aplikacji	2
4. Funkcjonalności Aplikacji	2
4.1. Uwierzytelnianie Użytkowników	2
4.2. Zarządzanie Notatkami	3
4.3. Informacje Pogodowe	3
5. Wykorzystane Technologie i Biblioteki	4
6. Instalacja i Uruchomienie	4
7. Struktura Kodu (plik main.dart)	5



1. Wprowadzenie
Niniejszy dokument przedstawia dokumentację techniczną i funkcjonalną aplikacji mobilnej QuickNotes, zrealizowanej w technologii Flutter. Aplikacja ma na celu ułatwienie użytkownikom zarządzania osobistymi notatkami oraz zapewnia dodatkową funkcjonalność w postaci wyświetlania aktualnych danych pogodowych.
________________________________________
2. Cel Projektu
Głównym celem projektu QuickNotes jest stworzenie intuicyjnego i funkcjonalnego narzędzia, które pozwoli użytkownikom na:
•	Bezpieczne przechowywanie notatek z możliwością dołączania zdjęć.
•	Efektywne zarządzanie priorytetami notatek.
•	Prywatność i bezpieczeństwo danych poprzez system uwierzytelniania użytkowników.
•	Szybki dostęp do informacji pogodowych dla wybranego miasta.
________________________________________
3. Architektura Aplikacji
Aplikacja QuickNotes operuje w modelu klient-serwer w odniesieniu do danych pogodowych (klient mobilny komunikuje się z zewnętrznym API), natomiast wszystkie dane użytkowników i notatek są przechowywane lokalnie na urządzeniu w bazie danych SQLite.
Kluczowe komponenty architektoniczne:
•	Interfejs Użytkownika (UI): Zbudowany w oparciu o framework Flutter, wykorzystujący zasady Material Design dla spójnego i nowoczesnego wyglądu.
•	Warstwa Danych: 
o	Lokalna Baza Danych: Używa sqflite do implementacji bazy danych SQLite, w której przechowywane są dane użytkowników (tabela users) oraz ich notatki (tabela notes).
o	Usługa Pogodowa: Klasa WeatherService odpowiedzialna za komunikację z zewnętrznym API OpenWeatherMap, pobierając aktualne dane pogodowe.
•	Logika Biznesowa: Implementowana w klasach StatefulWidget, które zarządzają stanem aplikacji, obsługują interakcje użytkownika oraz koordynują operacje na bazie danych i z usługami zewnętrznymi.
________________________________________
4. Funkcjonalności Aplikacji
Aplikacja QuickNotes oferuje następujące główne funkcjonalności:
4.1. Uwierzytelnianie Użytkowników
•	Rejestracja: Użytkownik może utworzyć nowe konto, podając unikalną nazwę użytkownika i hasło. Hasła są bezpiecznie haszowane za pomocą algorytmu SHA-256 przed zapisaniem w bazie danych.
o	Logowanie: Zarejestrowany użytkownik może zalogować się, podając swoją nazwę użytkownika i hasło. System weryfikuje poprawność danych w lokalnej bazie danych. Po pomyślnym zalogowaniu, użytkownik jest przenoszony do ekranu notatek.
4.2. Zarządzanie Notatkami
•	Wyświetlanie Notatek: Po zalogowaniu, użytkownik widzi spersonalizowaną listę wszystkich swoich notatek, posortowanych malejąco według daty utworzenia.
o	Dodawanie Notatek: Użytkownik może dodać nową notatkę, wprowadzając tytuł, treść oraz wybierając priorytet (Niski, Średni, Wysoki). Istnieje również możliwość dołączenia zdjęcia do notatki, wybranego z galerii urządzenia lub zrobionego aparatem. Dołączone zdjęcia są kopiowane do katalogu dokumentów aplikacji.
o	Edycja Notatek: Istniejące notatki mogą być łatwo edytowane, co pozwala na modyfikację ich tytułu, treści, priorytetu oraz dołączonego obrazu.
•	Szczegóły Notatki: Kliknięcie na notatkę w widoku listy otwiera ekran szczegółów, gdzie wyświetlany jest pełny tytuł, treść, dołączony obraz (jeśli istnieje) oraz priorytet.
o	Priorytety Notatek: Notatki mogą mieć przypisany jeden z trzech priorytetów:
o	Niski: Oznaczony kolorem zielonym.
o	Średni: Oznaczony kolorem pomarańczowym.
o	Wysoki: Oznaczony kolorem czerwonym. Priorytet jest wyraźnie wizualizowany zarówno na liście notatek, jak i w widoku szczegółów.
4.3. Informacje Pogodowe
•	Wyświetlanie Pogody: Na ekranie głównym aplikacji, użytkownik może wprowadzić nazwę miasta, aby pobrać i wyświetlić aktualne dane pogodowe, takie jak temperatura i opis warunków, dostarczone przez OpenWeatherMap API.
o	Odświeżanie Danych: Dostępna jest ikona odświeżania, która umożliwia ręczne zaktualizowanie danych pogodowych dla wybranego miasta.
•	Obsługa Błędów: Aplikacja informuje użytkownika o wszelkich problemach z pobieraniem danych pogodowych, np. w przypadku nieznanej nazwy miasta lub problemów z połączeniem sieciowym.
________________________________________
5. Wykorzystane Technologie i Biblioteki
Projekt QuickNotes został zrealizowany przy użyciu następujących technologii i bibliotek:
•	Flutter: Framework UI do budowy natywnie skompilowanych aplikacji mobilnych, webowych i desktopowych z pojedynczej bazy kodu.
•	Dart: Język programowania używany przez Fluttera.
•	sqflite: Wtyczka Fluttera umożliwiająca integrację z bazami danych SQLite.
•	path_provider: Wtyczka do uzyskiwania dostępu do ścieżek katalogów systemu plików (np. katalogu dokumentów aplikacji, gdzie przechowywane są zdjęcia).
•	uuid: Biblioteka do generowania unikalnych identyfikatorów (UUID), używanych do nadawania unikalnych ID notatkom i użytkownikom.
•	image_picker: Wtyczka do łatwego wybierania zdjęć z galerii urządzenia lub robienia nowych zdjęć za pomocą aparatu.
•	http: Pakiet do wykonywania żądań HTTP, wykorzystywany do komunikacji z OpenWeatherMap API.
•	crypto: Pakiet Dart do operacji kryptograficznych, używany do haszowania haseł za pomocą algorytmu SHA-256.
________________________________________
6. Instalacja i Uruchomienie
Aby skompilować i uruchomić aplikację QuickNotes, wykonaj poniższe kroki. Upewnij się, że masz zainstalowane środowisko Flutter i odpowiednio skonfigurowany emulator lub fizyczne urządzenie mobilne.
1.	Sklonuj repozytorium projektu: git clone [link_do_repozytorium_github]
2.	Przejdź do katalogu projektu: cd quicknotes
3.	Pobierz zależności Fluttera: flutter pub get
4.	Uruchom aplikację: flutter run Aplikacja zostanie uruchomiona na podłączonym urządzeniu lub w aktywnym emulatorze.
________________________________________
7. Struktura Kodu (plik main.dart)
Cała logika aplikacji, definicje UI oraz funkcje zarządzania danymi są zawarte w pojedynczym pliku main.dart dla uproszczenia projektu. Główne sekcje pliku to:
•	Importy: Zestawienie wszystkich wymaganych pakietów i bibliotek.
•	Inicjalizacja Bazy Danych: Globalna instancja _appDatabase i asynchroniczna funkcja _initAppDatabase odpowiedzialna za tworzenie i otwieranie bazy danych, w tym definicje tabel users i notes.
•	Funkcja main: Punkt wejścia aplikacji, który inicjalizuje Fluttera i bazę danych, a następnie decyduje o początkowym ekranie (logowanie lub rejestracja) w zależności od istnienia użytkowników.
•	Typy Enum i Rozszerzenia: Definicje NotePriority oraz rozszerzenia NotePriorityExtension do obsługi priorytetów notatek (wyświetlanie tekstu i kolorów).
•	Funkcje Pomocnicze: _hashPassword do haszowania haseł.
•	Klasy Widgetów (Ekrany UI): 
o	QuickNotesApp: Główny widget aplikacji.
o	LoginScreen: Ekran logowania użytkownika.
o	RegistrationScreen: Ekran rejestracji nowego konta.
o	NotesScreen: Główny ekran z listą notatek i funkcjonalnością pogodową.
o	NoteDetailScreen: Ekran wyświetlający szczegóły pojedynczej notatki.
•	Klasa Serwisu: WeatherService: Klasa odpowiedzialna za komunikację z OpenWeatherMap API.
________________________________________
Aplikacja QuickNotes jest funkcjonalnym przykładem aplikacji mobilnej Flutter, która integruje lokalne zarządzanie danymi z zewnętrznymi usługami sieciowymi. Projekt demonstruje kluczowe aspekty tworzenia aplikacji, takie jak uwierzytelnianie, trwałe przechowywanie danych oraz dynamiczne interfejsy użytkownika.

=======
# quick_desktop

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 1902c03 (QuickNotes)
