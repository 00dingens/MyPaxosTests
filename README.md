Notizen
=======

Hier sammle ich Notizen zur Wahl einer geegneten Implementation von Paxos o.ä.
Ich habe einige Implementationen schnell gestestet, dabei ging es vor allem um Machbarkeit (Doku intakt?), Speichereffizienz, Geschwindigkeit und Robustheit.


Aufgabe
=======

In der Anlage die Masterarbeit von Ole Rixmann bzgl. der Paxos Implmentation [DIKE] welche mit der Paxos Implementation von basho [ENSEMBLE] verglichen werden sollte. Die Frage stellt sich, müssen wir
eine eigene Paxos Implementation haben oder ist es besser dem ensemble zu folgen. Darüber hinaus finde ich bei dem Thema auch noch [nkbase] interessant.
(Nachträglich kamen auch noch [CloudI] und [Mnesia] ins Gespräch.)

[DIKE]: <https://github.com/travelping/dike>

[ENSEMBLE]: <https://github.com/basho/riak_ensemble>

[nkbase]: <https://github.com/Nekso/nkbase>

[CloudI]: <http://cloudi.org>

[Mnesia]: <https://de.wikipedia.org/wiki/Mnesia>

Wichtig im SCG: C, TPOSS-PCS: c, CCS: C, MAR: AP


Paxos
=====

Rollen: Client, {Acceptor, Proposer, Learner}, Leader

Basic: Prepare!, Promise, Accept!, Accepted

Multi (nach einem Basic): Accept!, Accepted

Fast und General siehe <http://en.wikipedia.org/wiki/Paxos_(computer_science)>

Für Routing Tables reicht ein einfacher Paxos (s. Riak-Ensemble Vortrag, 14:50)


DIKE
====

<https://github.com/travelping/dike> - Ist Dike immer noch wenig optimiert?

Master: verteilt auf 5 Knoten

Ist der Hashring Teil von Dike? (Oles Diplomarbeit, S.31) -> Im Code gibt es einen Hashring.

Deps: Lager(Basho), Regine(Travelping)


Installation
------------

### rebar:

    https://github.com/rebar/rebar.git
    nach Anleitung, dann
    export PATH=$PATH:~/tp/rebar

### dike:

    rebar.config:
    {erl_opts, [debug_info, {parse_transform, lager_transform}]}.
    ->
    {erl_opts, [debug_info, {lager_transform, parse_transform}]}.
    dann
    rebar get-deps
    rebar compile
oder
    "with mix" nach Anleitung

### tetrapak:

    https://github.com/travelping/tetrapak
    installieren als su
    export PATH=$PATH://usr/local/lib/erlang/bin/

### test:

    "tetrapak test" gibt nichts aus. Keine Fehler, keine Erfolgsmeldungen.
    mix ct geht. (TEST COMPLETE, 5 ok, 0 failed, 1 skipped of 6 test cases)

TODO: im Einsatz testen.


### Pro:

- Spezifische Lösung
- Schon im Einsatz
- Simple Implementation, nicht optimiert (S.31)
- Hashring?

### Con:

- Master? Oder ist das nur die Benennung?
- Kein Multi-Paxos? (S.72)
- Kein Hot-Code-Swapping (S.72)


Riak ENSEMBLE
=============

Riak-Core Vortrag: <https://youtu.be/gXJxbhca5Xg> (Paxos 14:20) (MultiPaxos 16:20) (Ring 23:30) (Epoch 27:20)

Riak-Ensemble Vortrag: <https://youtu.be/ITstwAQYYag> (CAP 3:10) (Consensus 8:00) (Paxos ...) (Multi-Paxos 12:20) (Zab 17:40) (Raft 18:45) (Riak-ensemble 19:40) (Architecture 37:00)

Deps (43MB): Lager(Basho), Eleveldb(Basho) -> cuttlefish(Basho) Brauch nicht Riak(-Core).

### Pro:

-   Viele Entwickler und Nutzer
-   Besser optimiert? -> Code ansehen?

### Con:

-   Deps?


Riak Core
---------

<http://basho.com/where-to-start-with-riak-core/>

<irc://freenode.net/#riak>

<http://www.erlang-factory.com/upload/presentations/255/RiakInside.pdf>


NkBase
======

<https://github.com/Nekso/nkbase> Klingt gut.

Deps (91MB): Riak-core(Basho), Riak-dt(Basho), Cluster-info(Basho), Sext(Uwiger)

Setzt auf Riak-Core auf. No Master

Installation und Test
---------------------

    https://github.com/Nekso/nkbase.git nach Anleitung geht einwandfrei.

### Test auf 5 Knoten

- Vorher

        RAM 45 45 45 45 45 MB
        log 12KB
        HDD-Ordner 47 47 5 5 47 MB

- Schreibe 2 Mio Datensätze (133B) der Form:

        {{name,"horst1000000"},
        {number,1000000},
        {street,"1000000street"},
        {city,"city2000000"},
        {country,"1000000th country"},
        {value,119000000}}

  Code

        sx(0) -> ok;
        sx(N) -> nkbase:put(domain, class, integer_to_list(N), entry(N)), sx(N-1).
        entry(N) -> {
        {name,"horst"++integer_to_list(N)},
        {number,N},
        {street,integer_to_list(N)++"street"},
        {city,"city"++integer_to_list(N*2)},
        {country,integer_to_list(N)++"th country"},
        {value,N*119}
        }.

- Laufzeit 23 Min. (CPU-Zeit 6-14 Min pro Prozess)

- Nachher

        RAM     76 380 75 370 385 MB
        RamKomp 19  22 13  20  20 MB
        log 12KB
        Ordner 190 135 135 68 68 MB
        nach einer weile:
        Ordner 400 220 290 95 95 MB
        
        NetzTraffic 1000 400 375 320 135 MB gesendet
                     270 570 580 570 260 MB empfangen

- Wenn ein Knoten ausfällt ist das kein Ding.
- Zwei auch nicht.
- 3 von 5 abgeschossen, jetzt können Werte nicht geschrieben werden. Wurde erst repariert, als wieder 4 on waren.
- Wenn Knoten ausgefallen waren und wieder on kommen, werden die Daten repariert. Die Daten von Platte sind sofort da, die von anderen Knoten werden angefordert/repariert.
- Test: bei 2 knoten X,Y mit X schreiben, X abschießen, Z starten. daten sind da.
- Interessant wäre ein netsplit test. vielleicht später... (Szenario zB. 3/2 split, auf die 3 schreiben, davon 2 abschießen, netz wieder zusammenfügen (1 mit neuer info, 2 mit altem stand) schauen, welcher Stand propagiert wird.)


### Pro:

- Installation und Test problemlos.
- Starten, einfaches Konfigurieren, Put und Get sind leicht zu bedienen. 


Mnesia
======

[Mnesia Doc](http://www.erlang.org/doc/man/mnesia.html)

<http://www.doc.ic.ac.uk/~rn710/Installs/otp_src_17.0/lib/mnesia/test/mnesia_majority_test.erl> Mnesia Majority Test -> TODO Testen

<https://de.wikipedia.org/wiki/Mnesia> Wikipedia übersicht (repariert)

<http://learnyousomeerlang.com/mnesia> Gute Einführung: 
*"If we refer to the CAP theorem, Mnesia sits on the CP side, rather than the AP side, meaning that it won't do eventual consistency, will react rather badly to netsplits in some cases, but will give you strong consistency guarantees if you expect the network to be reliable (and you sometimes shouldn't)."*

<http://stackoverflow.com/questions/787755/how-to-add-a-node-to-an-mnesia-cluster>

Irgendwer schrieb, dass Mnesia eher für etwa 10 Knoten gut geht -> nachsehen, warum.

Leere DB: ca 20kb

Test mit 5 Knoten
----

- Vorher

        RAM je ~30MB (vorher mal 20MB)
        mit disc_copies:
        test:put(10000).
          führt auf anderen Knoten zu 
        =ERROR REPORT==== 3-Sep-2015::09:46:36 ===
        Mnesia('n1@roots-MacBook-Pro'): ** WARNING ** Mnesia is overloaded: {dump_log,write_threshold}

Erklärung dazu auf <http://streamhacker.com/2008/12/10/how-to-eliminate-mnesia-overload-events/>
also gehts weiter mit ram_copies.

- schreib test 2.000.000 x ca. 100 B

        Start 10:05 Ende 10:24 -> Laufzeit 19 Min

- ca 100K Datensätze/Min

        RAM       90M 1.9G 1.9G 1.9G 1.9G
        RAM komp. 70M 1.6G 1.6G 1.6G 1.6G
        Platte 8KB (TODO auch mit Platte testen)
        Netztraffic 2.8G 200M 200M 200M 200M gesendet
                    820M 720M 720M 720M 720M empfangen
        Pakete: pro datensatz: 3 hin, 2 zurück

- Knoten abgeschossen, wieder verbunden -> sofort 1.7G RAM (teilen die sich vllt speicher?) Netsplit auf verschiedenen Rechnern testen.
- Sowohl Haupt als auch Nebenknoten können abgeschossen und problemlos wieder verbunden werden.
- Schreiben + Lesen geht auch, wenn alle anderen Knoten weg sind. -> **Netsplit könnte hässlich werden.** (TODO)
- Daten können von X gelesen werden, wenn sie in Abwesenheit von X geschrieben wurden.
- Wenn alle Knoten aus sind, sind die Daten weg :)

Pro
---

- Erlang out of the box

Con
---

- Netsplit wird hässlich 


CloudI.org
==========

50-100 Machines in LAN

<http://cloudi.org/faq.html#1_Messaging>
<https://github.com/okeuday/cpg>

CloudI vs Nekso
---------------

CloudI is focused on LAN usage of a smallish cluster (50-100 machines, limited by distributed Erlang communication, focusing on fault-tolerance which requires the low latency on LANs) for supporting the execution of services (microservices, potentially long-running source code where service execution is 1 or more thread of execution, not processing data as batch task processing (i.e., not job processing) but instead soft-realtime event processing of message flows (service requests and their associate response, if a response is provided)) which may be implemented in any programming language (so bringing fault-tolerance into any non-Erlang programming language using concepts found in Erlang, but made generic with extra features for efficient fault-tolerance and scalability).

Nekso (nkcore, nkcluster, etc.) is focused on both LAN and WAN usage with execution of jobs (batch processing of data), but without explicitly focusing on fault-tolerance features (i.e., fault-tolerance constraints: timeouts that are enforced with message flows, max_r/max_t restarts of processing, transaction processing).

Nekso is using riak_core which attempts to provide globally consistent state while CloudI uses cpg.  The cpg usage in CloudI is not focused on consistency, but instead on partition tolerance and availability, due to needing fault-tolerant service naming, so a service dies... its name disappears, lookups still see the name with other instances of the same service or perhaps a different implementation of the same service, so the service request is still handled after the death of 1 or more services.  CloudI execution is not focused on consistency, since it is providing RESTful development where the only state storage is for caching, the rest is transaction processing of critical transactions which must scale and be fault-tolerant.

The fact Nekso is attempting to pursue WAN processing is interesting, but I don't see the same level of focus on WAN fault-tolerance that I have seen in Linux-HA, and with the Kademlia distributed hash table algorithm.  While it would be nice if there was overlap with Nekso and CloudI to create more development together, the focuses due appear to be separate purposes that do not overlap.  I think Nekso could utilize CloudI for some of what they are doing, but they may not have seen a need to do so at this time. Either way, I am not attempting to prevent them from contributing to CloudI at all, I just believe that they are pursuing a different set of requirements with the Nekso source code.


If you are doing Erlang-only development, you could use the separate CloudI repositories to manage everything
as rebar or hex dependencies (i.e., use the repository <https://github.com/CloudI/cloudi_core/> or the
hex package at <https://hex.pm/packages/cloudi_core>).

The example at <https://github.com/CloudI/CloudI/tree/develop/examples/hello_world5> shows how source code can be structured for this approach.

Installation
------------
<http://cloudi.org/faq.html#3_Overview> und 
<http://cloudi.org/index.html> Abhängigkeiten in *configure* brauchen aufm Mac gerade zu lange. (<https://www.macports.org/install.php>)

<https://github.com/CloudI/CloudI> Viele Abhängigkeiten, einige lassen sich nicht fehlerfrei installieren. (gmp, boost)

examples wie <https://github.com/CloudI/CloudI/tree/develop/examples/hello_world5> unklare Anweisungen, funktioniert nicht.

Aus Zeitgründen abgebrochen.

Pro
---

- schneller Kontakt zu Entwicklern (nicht selbst getestet)

Con
---

- geht nicht auf Anhieb
- viele Abhängigkeiten


Alternativen
============


Raft
----

Einfacher als Paxos, weil aufgeteilt, Leader mit Heartbeat.

<http://en.wikipedia.org/wiki/Raft_(computer_science)>

Demo <https://raft.github.io>

### Implementationen

-   <https://github.com/andrewjstone/rafter>
    Wird nicht aktiv supportet!

-   <https://github.com/dreyk/zraft_lib>
    Test hat funktioniert, nach kleiner Korrektur:

         ".*",{git, "git://github.com:dreyk/zraft_lib.git", {branch, "master"}}},
        ->
         ".*",{git, "git://github.com/dreyk/zraft_lib.git", {branch, "master"}}},

    ZRaft hat 12MB deps.

-   <https://github.com/cannedprimates/huckleberry> bzw.
    <https://ramcloud.atlassian.net/wiki/display/logcabin/LogCabin>
    Hier gibts einiges an Links, habe es noch nicht getestet.

-   Raft in vielen Sprachen: <raftconsensus.github.io>


ZooKeeper
---------

ZooKeeper Atomic Broadcast@Hunt10 von Yahoo (Riak-Ensemble Vortrag (s.o.) 17:38)

Es gab wohl auch eine riak-zk implementation, habe ich nicht mehr gefunden.

<https://github.com/huaban/erlzk> ...sieht gut aus

<https://github.com/campanja/ezk> ...sieht schwach aus


Chandra–Toueg
-------------

(eventually strong failure detector)
<http://en.wikipedia.org/wiki/Chandra-Toueg_consensus_algorithm>


Alternativen in Elixir
----------------------

<http://elixir-lang.org/crash-course.html>


Vergleich
=========

|Name         |   Deps    | Test  |  Stil |  Mem. |  Master |  Log  | Heartbeat | Community |    Optimierungen   |
|:------------|----------:|:-----:|:-----:|:-----:|:-------:|:-----:|:---------:|:---------:|:------------------:|
|DIKE         |**3,5MB**  | geht  |   ?   |   ?   |  vert.  |   ?   |     -     |    TP     |       ?            |
|RIAK-Ensemble|   43MB    | TODO  |   ?   |   ?   |    ?    |   ?   |     -     |   Groß    |                    |
|NkBase       | **91MB**  |**top**|  gut  | 45+MB |  kein   |normal |   nein    |    ?      |                    |
|CoudI.org    |   viele   |       | nett  |       |         |       |           |           |                    |
|Mnesia       |    0B     | joa   |  gut  |  erl  |    ?    | kaum  |   nein?   |   erl     |                    |
|ZRaft        |   12MB    | geht  |   ?   |   ?   |    ?    |   ?   |    ja     |    ?      |                    |
|ZooKeeper    |           |       |       |       |         |       |           |           |                    |
|(Menicus)    |     -     |   -   |   -   |   -   | rotiert |   -   |   nein    |   keine   | WAN und Scalability|


Papers
======

**Kothandaraman15** Datenverkehr soll über einen anderen Knoten geleitet werden. Statt Pakete im Controller zu Puffern wird das zwischen Src und Dst ausgemacht, ist schneller und skaliert, weil der Controller konstante Kosten hat.
(*Babu Kothandaraman, Manxing Du, and Pontus Sköldström. Centrally controlled distributed NFV state management, 2015. unpublished yet.*)

**Sonkoly15** Netzwerk-Funktionen und -Ressourcen werden virtualisiert. Das ist modular und hierarchisch möglich. Das Paper finde ich schwer verständlich. Vielleicht helfen mir ausführlichere Beschreibungen, wie z. B. Szabo14 (*R. Szabo et al. D2.2: Final architecture, 2014*).
(*Balázs Sonkoly, Robert Szabo, Dávid Jocha, János Czentye, Mario Kind, and Fritz-Joachim Westphal. UNIFYing cloud and carrier network resources: An architectural view, 2015. unpublished yet.*)

**Szabo15** Die Kontrollarchitektur von UNIFY macht die Kommunikationswege von NFC einfacher und schneller. Alle
Kontrollmöglichkeiten können für optimale Steuerung der Kommunikation genutzt werden, ohne jene explizit offenzulegen.
(*Robert Szabo, David Jocha, and Janos Elek. Network function chaining in DCs: Towards a joint compute & network virtualization and programming, 2015. unpublished yet.*)

**Mao: Menicus-Replicated Machines for WAN**
Rotierender Leader, theoretisch werden null-Operationen gebroadcastet, praktisch kann das weggelassen werden bzw. implizit geschehen. Lässt sich aus Paxos herleiten, verteilt die Last gut in WAN. Implementationen finde ich nicht.


Akronyme
--------

-   [AAA] Authentication, Authorization and Accounting
-   [ETSI] European Telecommunication Standards Institute
-   [IDS] Intrusion Detection System
-   [ISP] Internet Service Provider
-   [IETF] Internet Engineering Task Force
-   [LDR] Location Data Repository
-   [NAT] Network Address Translation 
-   [NFV] Network Function Virtualisation 
-   [ONF] Open Networking Forum
-   [PCS] policy control server
-   [SCG] Session Control Gateway
-   [SDN] Software Defined Network 
-   [SFC] Service Function Chaining
-   [TPOSS] Travelping Open Subscriber Server
-   [UDR] User Data Repository
-   [WTP] Wireless Termination Point


Fragen
======

-   Ist es Absicht, dass viele Github Projekte irgendeinen Fehler mitbringen?
-   Wie wichtig ist *wenig Speicherbedarf*? -> Riak-Core braucht Speicher
    Falls Speicher nicht so wichtig ist: NKBase ist Cool.
-   Ist ein *Heartbeat* eine Option? -> Raft arbeitet mit einem Heartbeat.


Erlang
======

IntelliJ
--------

- <https://www.jetbrains.com/idea/download/>
- <https://www.jetbrains.com/idea/download/download_thanks.jsp>
- <http://ignatov.github.io/intellij-erlang/>


Markdown
========

- <https://help.github.com/articles/github-flavored-markdown/>
- <https://help.github.com/articles/writing-on-github/>


Git
===

[Schnelle Anleitung](http://rogerdudler.github.io/git-guide/)


TODO
====

- Diese Datei auf englisch übersetzen?
- Dike nochmal testen und hier aufnehmen.
- An Ole und Carmen: Wo hat es mit Dike gehapert (in der Readme), was fehlt mir da?
- Meine Tests zu Git hochladen
- Mail an alle in der Runde mit Link zu meinen Tests
- Netsplit in verschiednen Varianten testen
- Speicher von Erlang aus messen


Sollte ich mal ansehen
----------------------

- OpenStack
- OpenNF
- OpenFlow
- OpenDaylight
- RADIUS
- Diameter
- TACACS+
- Cockroach
- Scalaris
- Ldub

