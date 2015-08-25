Notizen
=======

Hier sammle ich Notizen zur Wahl einer geegneten Implementation von Paxos o.ä.


Aufgabe
=======

In der Anlage die Masterarbeit von Ole Rixmann bzgl. der Paxos Implmentation DIKE[^1] welche mit der Naxos Implementation von basho ENSEMBLE[^2] verglichen werden sollte. Die Frage stellt sich, müssen wir
eine eigene Paxos Implementation haben oder ist es besser dem ensemble zu folgen. Darüber hinaus finde ich bei dem Thema auch noch nkbase[^3] interessant.

[^1]: <https://github.com/travelping/dike>

[^2]: <https://github.com/basho/riak_ensemble>

[^3]: <https://github.com/Nekso/nkbase>


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

Ist der Hashring Teil von Dike? (S.31) -> Im Code gibt es einen Hashring.

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

### tetrapak:

    https://github.com/travelping/tetrapak
    installieren mit su
    export PATH=$PATH://usr/local/lib/erlang/bin/

### test:

    test/test_SUITE.erl:
    -compile([{parse_transform, lager_transform}]).
    ->
    -compile([{lager_transform, parse_transform}]).
    tests gehen nicht:
    - - - - - - - - - - - - - - - - - - - - - - - - - -
    dike_SUITE:init_per_suite failed
    Reason: undef
    - - - - - - - - - - - - - - - - - - - - - - - - - -
    Testing tp.dike: *** FAILED {dike_SUITE,init_per_suite} ***
    Testing tp.dike: TEST COMPLETE, 0 ok, 0 failed, 6 skipped of 6 test cases

**TODO:** nochmal, weil sich der Code inzwischen geändert hat.

### Pro:

-   Spezifische Lösung
-   Simple Implementation, nicht optimiert (S.31)
-   Hashring?

### Con:

-   Master? Oder ist das nur die Benennung
-   Kein Multi-Paxos (S.72)
-   Kein Hot-Code-Swapping (S.72)


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

### Pro:

-   Installation und Test problemlos.

### Con:

-   Sicherheit? (wegen dezentralität)
-   Produziert massiv Log-Daten (Kann man die ausschalten? Sind die nützlich -> Pro?)


Alternativen
============


Raft
----

Einfacher als Paxos, weil aufgeteilt, Leader mit Heartbeat.

<http://en.wikipedia.org/wiki/Raft_(computer_science)>

Implementationen:

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

ZooKeeper Atomic Broadcast@Hunt10 von Yahoo (Riak-Ensemble Vortrag 17:38)

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
|DIKE         |**3,5MB**  | fail  |   ?   |   ?   |  vert.  |   ?   |     -     |    TP     |       ?            |
|RIAK-Ensemble|   43MB    | TODO  |   ?   |   ?   |    ?    |   ?   |     -     | **Groß**  |                    |
|NkBase       | **91MB**  | super |  gut  |   ?   |    -    |  Viel |     -     |    ?      |                    |
|ZRaft        |   12MB    | geht  |   ?   |   ?   |    ?    |   ?   |    ja     |    ?      |                    |
|ZooKeeper    |           |       |       |       |         |       |           |           |                    |
|Menicus      |     -     |   -   |   -   |   -   | rotiert |   -   |   nein    |   keine   | WAN und Scalability|


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


Sollte ich mal ansehen
----------------------
-   OpenStack
-   OpenNF
-   OpenFlow
-   OpenDaylight
-   RADIUS
-   Diameter
-   TACACS+
-   Mnesia


Fragen
======

-   Ist es Absicht, dass viele Github Projekte irgendeinen Fehler mitbringen?
-   Wie wichtig ist *wenig Speicherbedarf*? -> Riak-Core braucht Speicher, Logs brauchen Speicher...
    Falls Speicher nicht so wichtig ist, oder Logs abgeschaltet werden können: NKBase ist Cool.
-   Ist ein *Heartbeat* eine Option? -> Raft arbeitet mit einem Heartbeat.
-   Um wieviele Knoten geht es hier?
-   Wieviele Daten/Anfragen sollen verarbeitet werden? Wenig -> eigener Paxos; Viel -> optimierungen Interessant
-   Sollte die *Netzstruktur* berücksichtigt werden? -> Z.B. Leader in der Mitte oder keinen Leader.
    Menicus wäre hier interessant, könnte vllt. auch in bestehende Paxos-Implementationen eingebracht werden.


Erlang
======

IntelliJ
--------

-   <https://www.jetbrains.com/idea/download/>
-   <https://www.jetbrains.com/idea/download/download_thanks.jsp>
-   <http://ignatov.github.io/intellij-erlang/>


Markdown
========

-   <https://help.github.com/articles/github-flavored-markdown/>
-   <https://help.github.com/articles/writing-on-github/>
