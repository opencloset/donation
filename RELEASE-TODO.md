v0.5.15

    $ grunt

v0.5.14

    $ grunt


v0.5.13

    $ grunt

v0.5.12

    $ grunt

v0.5.11
v0.5.10

    mysql> INSERT INTO `event_type` (`type`, `domain`, `desc`, `create_date`, `update_date`) VALUES
             ('', 'donation', 'default 기증 이벤트 타입', NOW(), NOW());
    mysql> UPDATE event SET event_type_id = 5 WHERE id IN (1, 2);

v0.5.9
v0.5.8
v0.5.7
v0.5.6
v0.5.5

    $ mysql -u opencloset -p opencloset < OpenCloset-Schema/db/alter/140-event.sql
    $ closetpan OpenCloset::Schema    # 0.057

v0.5.4

v0.5.3

v0.5.2

v0.5.1

    $ grunt

v0.5.0

v0.4.10

    $ mysql -u opencloset -p opencloset < OpenCloset-Schema/db/alter/128-add-status.sql
    $ closetpan OpenCloset::Common    # v0.1.1
    $ grunt
