/*DROP TABLE IF EXISTS keywords;
CREATE TABLE keywords 
(
    id int primary key auto_increment,
    name varchar(250)
);
CREATE UNIQUE INDEX keywords_name_idx ON keywords (name);

DROP TABLE IF EXISTS post_keywords;
CREATE TABLE post_keywords
(
    post_id int,
    keyword_id int,
    PRIMARY KEY (post_id, keyword_id)
);*/

/*DROP TABLE IF EXISTS t_keywords;
CREATE TEMPORARY TABLE t_keywords(
    id int primary key auto_increment,
    name varchar(250) 
);

DROP TABLE IF EXISTS t_post_keywords;
CREATE TEMPORARY TABLE t_post_keywords(
    post_id int,
    keyword_id int,
    PRIMARY KEY (post_id, keyword_id)
);*/
/*DROP TABLE IF EXISTS post_category;
CREATE TABLE post_category(
    post_id INT,
    category_id INT,
    PRIMARY KEY(post_id, category_id)
);*/

DROP FUNCTION IF EXISTS expand_keywords;
delimiter //
CREATE FUNCTION expand_keywords(_post_id INT, _keywords text) RETURNS INT
BEGIN
    DECLARE _pos INT;
    DECLARE _old_pos INT;
    DECLARE _keyword VARCHAR(255);
    DECLARE _keyword_id INT;
    DECLARE CONTINUE HANDLER FOR 1062 /* duplicate entry */ BEGIN END;
        IF _keywords IS NULL OR _keywords = '' THEN
            RETURN 0;
        END IF;
        SET _old_pos = 1;
        keywords_loop: LOOP
            SET _pos = LOCATE(',', _keywords, _old_pos);
            IF _pos = 0 THEN
                SET _pos = LENGTH(_keywords) + 1;
            END IF;
            SET _keyword = LTRIM(SUBSTRING(_keywords, _old_pos, _pos - _old_pos)); 
            SET _old_pos = _pos + 1;
            IF _keyword = '' THEN
                LEAVE keywords_loop;
            END IF;
            
            SET _keyword_id = NULL;
            SELECT id INTO _keyword_id FROM keywords WHERE name = _keyword;
            IF _keyword_id IS NULL THEN
                INSERT INTO keywords (name) VALUES (_keyword);
                SELECT LAST_INSERT_ID() INTO _keyword_id;
            END IF;
            INSERT INTO post_keywords (post_id, keyword_id) VALUES (_post_id, _keyword_id);
        END LOOP keywords_loop;
        RETURN 1;
END//
delimiter ;

DROP FUNCTION IF EXISTS expand_category_ids;
delimiter //
CREATE FUNCTION expand_category_ids(_post_id INT, _cat_ids VARCHAR(200)) RETURNS INT
BEGIN
        DECLARE _pos INT;
        DECLARE _old_pos INT;
        DECLARE _id VARCHAR(200);
        IF _cat_ids IS NULL OR _cat_ids = '' THEN
            RETURN 0;
        END IF;
        SET _old_pos = 1;
        keywords_loop: LOOP
            SET _pos = LOCATE(',', _cat_ids, _old_pos);
            IF _pos = 0 THEN
                SET _pos = LENGTH(_cat_ids) + 1;
            END IF;
            SET _id = LTRIM(SUBSTRING(_cat_ids, _old_pos, _pos - _old_pos)); 
            SET _old_pos = _pos + 1;
            IF _id = '' THEN
                LEAVE keywords_loop;
            END IF;
            
            INSERT INTO post_category (post_id, category_id) VALUES (_post_id, CAST(_id AS UNSIGNED));
        END LOOP keywords_loop;
        RETURN 1;
END//
delimiter ;

DROP PROCEDURE IF EXISTS get_post_category_link;
delimiter //
CREATE PROCEDURE get_post_category_link()
BEGIN
    SELECT expand_category_ids(p.id, p.category) FROM dle_post p;
END//
delimiter ;

DROP PROCEDURE IF EXISTS get_keywords;
delimiter //
CREATE PROCEDURE get_keywords()
BEGIN
    SELECT expand_keywords(p.id, p.keywords) FROM dle_post p;
END//
delimiter ;

