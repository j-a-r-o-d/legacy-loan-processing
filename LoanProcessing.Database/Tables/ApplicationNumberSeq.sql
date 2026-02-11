-- Application number sequence definition
-- Used to generate unique sequential numbers for loan applications
-- Requirements: 2.5, 10.1

CREATE SEQUENCE [dbo].[ApplicationNumberSeq]
    AS INT
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 99999
    CYCLE
    CACHE 10;
GO
