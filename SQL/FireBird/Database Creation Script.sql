/********************* ROLES **********************/

/********************* UDFS ***********************/

/****************** SEQUENCES ********************/

/******************** DOMAINS *********************/

CREATE DOMAIN GUID
 AS CHAR(16) CHARACTER SET OCTETS
 NOT NULL
 COLLATE OCTETS;

/******************* PROCEDURES ******************/

SET TERM ^ ;
CREATE PROCEDURE SPCREATEDEPLOYMENT (
    APPLICATIONGUID GUID,
    "VERSION" VARCHAR(50),
    WHATSNEW VARCHAR(8192),
    ISIMMEDIATE BOOLEAN DEFAULT FALSE,
    ISSILENT BOOLEAN DEFAULT FALSE,
    ISMANDATORY BOOLEAN DEFAULT FALSE )
RETURNS (
    DEPLOYMENTGUID GUID )
AS
BEGIN SUSPEND; END^
SET TERM ; ^

/******************** TABLES **********************/

CREATE TABLE ADDRESS
(
  ADDRESSGUID GUID NOT NULL,
  STREETADDRESS VARCHAR(50),
  CITY VARCHAR(50),
  STATEPROVINCEGUID GUID,
  ZIPPOSTAL VARCHAR(10),
  CONSTRAINT PK_ADDRESS PRIMARY KEY (ADDRESSGUID)
);
CREATE TABLE APPLICATION
(
  APPLICATIONGUID GUID NOT NULL,
  APPLICATIONNAME VARCHAR(50) NOT NULL,
  ISTRIAL BOOLEAN NOT NULL,
  CONSTRAINT PK_APPLICATION PRIMARY KEY (APPLICATIONGUID)
);
CREATE TABLE COMPANY
(
  COMPANYGUID GUID NOT NULL,
  NAME VARCHAR(50) NOT NULL,
  COMPANYLOCATIONGUID GUID,
  CONSTRAINT PK_COMPANY PRIMARY KEY (COMPANYGUID)
);
CREATE TABLE COMPANYLOCATION
(
  COMPANYLOCATIONGUID GUID NOT NULL,
  COMPANYGUID GUID NOT NULL,
  LOCATIONGUID GUID NOT NULL,
  CONSTRAINT PK_COMPANYLOCATION PRIMARY KEY (COMPANYLOCATIONGUID)
);
CREATE TABLE COUNTRY
(
  COUNTRYGUID GUID NOT NULL,
  ABBREVIATION CHAR(2) NOT NULL,
  DESCRIPTION VARCHAR(50) NOT NULL,
  CONSTRAINT PK_COUNTRY PRIMARY KEY (COUNTRYGUID)
);
CREATE TABLE DEPLOYMENT
(
  DEPLOYMENTGUID GUID NOT NULL,
  UPDATEVERSION VARCHAR(50) NOT NULL,
  WHATSNEW VARCHAR(8192) NOT NULL,
  APPLICATIONGUID GUID NOT NULL,
  STATUS VARCHAR(50) DEFAULT 'Active' NOT NULL,
  CREATEDUTCDATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  ISMANDATORY BOOLEAN DEFAULT False NOT NULL,
  ISSILENT BOOLEAN DEFAULT False NOT NULL,
  ISIMMEDIATE BOOLEAN DEFAULT False NOT NULL,
  CONSTRAINT PK_DEPLOYMENT PRIMARY KEY (DEPLOYMENTGUID)
);
CREATE TABLE INSTALLATION
(
  INSTALLATIONGUID GUID NOT NULL,
  LOCATIONGUID GUID NOT NULL,
  DEVICEFINGERPRINT VARCHAR(2048) NOT NULL,
  APPLICATIONGUID GUID NOT NULL,
  DEVICEGUID GUID NOT NULL,
  CONSTRAINT PK_INSTALLATION PRIMARY KEY (INSTALLATIONGUID),
  CONSTRAINT UNQ_DEVICEGUID UNIQUE (DEVICEGUID)
);
CREATE TABLE INSTALLATIONDEPLOYMENT
(
  INSTALLATIONGUID GUID NOT NULL,
  DEPLOYMENTGUID GUID NOT NULL,
  ISAVAILABLE BOOLEAN NOT NULL,
  UPDATEDUTCDATE TIMESTAMP,
  LASTATTEMPTUTCDATE TIMESTAMP,
  UPDATERESULT VARCHAR(50) DEFAULT NULL,
  UPDATELOG VARCHAR(8192),
  AVAILABLEUTCDATE TIMESTAMP,
  RECEIVEDUTCDATE TIMESTAMP,
  CONSTRAINT PK_INSTALLATIONGUID PRIMARY KEY (INSTALLATIONGUID,DEPLOYMENTGUID)
);
CREATE TABLE LOCATION
(
  LOCATIONGUID GUID NOT NULL,
  ADDRESSGUID GUID,
  DESCRIPTION VARCHAR(50),
  LATITUDE FLOAT,
  LONGITUDE FLOAT,
  CONSTRAINT PK_LOCATION PRIMARY KEY (LOCATIONGUID)
);
CREATE TABLE STATEPROVINCE
(
  STATEPROVINCEGUID GUID NOT NULL,
  ABBREVIATION CHAR(2) NOT NULL,
  DESCRIPTION VARCHAR(50) NOT NULL,
  COUNTRYGUID GUID NOT NULL,
  CONSTRAINT PK_STATEPROVINCE PRIMARY KEY (STATEPROVINCEGUID)
);
/********************* VIEWS **********************/

/******************* EXCEPTIONS *******************/

/******************** TRIGGERS ********************/

SET TERM ^ ;
CREATE TRIGGER B4_INSERT_DEPLOYMENTGUID FOR DEPLOYMENT ACTIVE
BEFORE INSERT POSITION 0
AS 
BEGIN 
  IF (NEW.DeploymentGUID IS NULL) THEN 
  BEGIN 
    NEW.DeploymentGUID = gen_uuid(); 
  END 
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER B4_INSERT_STATEPROVINCE FOR STATEPROVINCE ACTIVE
BEFORE INSERT POSITION 0
AS 
BEGIN 
  IF (NEW.StateProvinceGUID IS NULL) THEN 
  BEGIN 
    NEW.StateProvinceGUID = gen_uuid(); 
  END 
END^
SET TERM ; ^

SET TERM ^ ;
ALTER PROCEDURE SPCREATEDEPLOYMENT (
    APPLICATIONGUID GUID,
    "VERSION" VARCHAR(50),
    WHATSNEW VARCHAR(8192),
    ISIMMEDIATE BOOLEAN DEFAULT FALSE,
    ISSILENT BOOLEAN DEFAULT FALSE,
    ISMANDATORY BOOLEAN DEFAULT FALSE )
RETURNS (
    DEPLOYMENTGUID GUID )
AS
BEGIN
	 select gen_uuid() from RDB$Database into :deploymentGUID;

	--create new Deployment record
	INSERT INTO DEPLOYMENT
           (
            DEPLOYMENTGUID
           ,UPDATEVERSION
           ,WHATSNEW
           ,APPLICATIONGUID
           ,ISIMMEDIATE
           ,ISSILENT
           ,ISMANDATORY
           )
     VALUES
           (
            :deploymentGUID
           ,:version
           ,:whatsNew
           ,:applicationGUID
           ,:IsImmediate
           ,:IsSilent
           ,:IsMandatory
           );
    
      	INSERT INTO INSTALLATIONDEPLOYMENT
			   (INSTALLATIONGUID
			   ,DEPLOYMENTGUID
			   ,ISAVAILABLE
			   ,AVAILABLEUTCDATE
			   ,UPDATEDUTCDATE
			   ,LASTATTEMPTUTCDATE
			   ,UPDATERESULT
			   ,UPDATELOG
			   )

			Select INSTALLATIONGUID 
			,:deploymentGUID
			,TRUE
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			from INSTALLATION;   
            
END^
SET TERM ; ^


ALTER TABLE ADDRESS ADD CONSTRAINT FK_ADDRESS_STATEPROVINCEGUID
  FOREIGN KEY (STATEPROVINCEGUID) REFERENCES STATEPROVINCE (STATEPROVINCEGUID);
ALTER TABLE DEPLOYMENT ADD CONSTRAINT INTEG_740
  CHECK  ((Status='Cancelled' OR Status='Completed' OR Status='Active'));
ALTER TABLE INSTALLATION ADD CONSTRAINT FK_APPLICATION
  FOREIGN KEY (APPLICATIONGUID) REFERENCES APPLICATION (APPLICATIONGUID);
ALTER TABLE INSTALLATIONDEPLOYMENT ADD CONSTRAINT FK_INSTALLATION
  FOREIGN KEY (INSTALLATIONGUID) REFERENCES INSTALLATION (INSTALLATIONGUID);
ALTER TABLE INSTALLATIONDEPLOYMENT ADD CONSTRAINT CK_INSTALLDEPLOYMENTRESULT
  CHECK  ((UpdateResult='Failure' OR UpdateResult='Success' OR UpdateResult=NULL));
GRANT EXECUTE
 ON PROCEDURE SPCREATEDEPLOYMENT TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON ADDRESS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON APPLICATION TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON COMPANY TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON COMPANYLOCATION TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON COUNTRY TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON DEPLOYMENT TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON INSTALLATION TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON INSTALLATIONDEPLOYMENT TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON LOCATION TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON STATEPROVINCE TO  SYSDBA WITH GRANT OPTION;

