CREATE SCHEMA targeting
--сейчас затачиваем под статьи
    CREATE TABLE object --targeting material (object)
    (
        id serial PRIMARY KEY, --unique id
        uuid uuid NOT NULL, -- UUID
        appid integer NOT NULL, -- application id
        name varchar NOT NULL, -- имя объекта
        object_url varchar NOT NULL, -- ссылка на объект таргетирования (на новость, видео) 
        link_text varchar NOT NULL, -- текст ссылки
        short_description varchar NOT NULL, -- краткий пояснительный текст рядом с картинкой
        image_url varchar, -- ссылка на изображение объекта
        content_type_id integer NOT NULL, -- id типа контента
        deleted boolean NOT NULL DEFAULT false, -- флаг, что объект удален
        FOREIGN KEY (content_type_id) REFERENCES content_type (id)
    )

    CREATE TABLE content_type -- типы контента
    (
        id serial PRIMARY KEY, --unique id
        content_type character(30) NOT NULL, -- тип контента
        name varchar NOT NULL, -- название типа контента
        deleted boolean NOT NULL DEFAULT false, -- флаг, что тип удален
    )

    CREATE TABLE application -- приложения
    (
        id serial PRIMARY KEY, -- unique id
        name varchar NOT NULL, -- название
        deleted boolean NOT NULL DEFAULT false -- флаг, что приложение удалено
    )
;
