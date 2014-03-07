CREATE SCHEMA analiticTest; 
    SET search_path TO analiticTest;
    CREATE TYPE gender_type AS ENUM ('male', 'female', 'both');
    CREATE TABLE names (
        id serial PRIMARY KEY,
        name varchar NOT NULL, --имя
        gender gender_type
    );
    CREATE TABLE url_by_gender_counter (
        id serial PRIMARY KEY,
        url varchar NOT NULL,
        is_male boolean NOT NULL,
        counter integer NOT NULL DEFAULT 0
    );
    CREATE INDEX urlByGenderCounter_url_idx ON urlByGenderCounter(url);
    CREATE INDEX urlByGenderCounter_url_is_male_idx ON urlByGenderCounter(url, is_male);
    CREATE TABLE post (
        id serial PRIMARY KEY,
        url varchar NOT NULL
    );
    CREATE TABLE comments (
        id serial PRIMARY KEY,
        name varchar, -- username
        comment_text text, --comment text
        user_id integer
    );
    CREATE TABLE users (
        id serial PRIMARY KEY,
        name varchar,
        full_name varchar
    );
    CREATE TABLE comment_to_post (
        post_id integer,
        comment_id integer,
        PRIMARY KEY (post_id, comment_id),
        FOREIGN KEY (post_id) REFERENCES post (id),
        FOREIGN KEY (comment_id) REFERENCES comments(id)
    );
    CREATE TABLE tags (
        id serial PRIMARY KEY,
        tag_name varchar NOT NULL
    );
    CREATE TABLE tag_to_post (
        post_id integer,
        tag_id integer,
        PRIMARY KEY (post_id, tag_id),
        FOREIGN KEY (post_id) REFERENCES post (id),
        FOREIGN KEY (tag_id) REFERENCES tags (id)
    );
