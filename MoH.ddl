--++++++++++++++++++++++++++++++++++++++++++++++
-- CREATE TABLES
-- Filename: MoH.ddl
-- Author: nanonite9
-- Date: October 2, 2018
-- Description: This file creates tables for the
-- Ministry of Health (MoH). It runs tables, 
-- referencing the E-R Diagram, filename: ER.pdf. 
--++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------
--  connect to database
------------------------------------------------
connect to csdb;

------------------------------------------------
--  DDL Statements for table Person
------------------------------------------------
CREATE TABLE Person (
  id CHAR(8) NOT NULL, -- associated with one person, must have
  first_name VARCHAR(25), -- nts: varchar gives up to 25 chars. char is exact
  last_name VARCHAR(25),
  gender VARCHAR(6),
  dob DATE,
  PRIMARY KEY(id) -- either a patient, physician or a nurse
);

------------------------------------------------
--  DDL Statements for table Address
------------------------------------------------
CREATE TABLE Address (
  id CHAR(8) NOT NULL,
  street VARCHAR(50),
  city VARCHAR(25),
  province VARCHAR(20),
  postal_code VARCHAR(6),
  PRIMARY KEY (id),
  FOREIGN KEY (id) REFERENCES Person (id)
    ON DELETE CASCADE
);

------------------------------------------------
--  DDL Statements for table Number
------------------------------------------------
CREATE TABLE Number (
  id CHAR(8) NOT NULL,
  num VARCHAR(15) NOT NULL, -- "at least one possibly more", prob should be int. idk. doesn't specify. varchar gives flexiblility
  num_type VARCHAR(10), --number_type CHAR(10),
  PRIMARY KEY (id, num),
  CHECK (num_type = 'home' OR num_type = 'work' OR num_type = 'mobile'),
  FOREIGN KEY (id) REFERENCES Person (id)
    ON DELETE CASCADE -- num_type associated with exactly one person
);

------------------------------------------------
--  DDL Statements for table Hospital
------------------------------------------------
CREATE TABLE Hospital ( -- above patient, physician and nurse... correct order: 
  hosp_name VARCHAR(100) NOT NULL, --"serves as identifier", long hospital names, you know
  street_address VARCHAR(50),
  city VARCHAR(25),
  annual_budget_CAD REAL,
  md_name CHAR(60) NOT NULL, --? do i need this here. yes.? "has to have at least one"
  PRIMARY KEY (hosp_name) --  FOREIGN KEY (hosp_name) REFERENCES Med_Dept (id)
);

------------------------------------------------
--  DDL Statements for table Med_Dept
------------------------------------------------
CREATE TABLE Med_Dept (
  md_name VARCHAR(60) NOT NULL, -- HOSPITAL "as at least one MED_DEPT", identifier
  hosp_name VARCHAR(100) NOT NULL, -- "hospital it belongs to", identifier, ..keep consistent with above.. why didnt i make person varchar? ...? should change.
  annual_budget_CAD REAL, -- allows for like $6.20.. must be CAD
  med_serv VARCHAR(100), -- "provides medical serives" ..number_type CHAR(10),
  PRIMARY KEY (md_name, hosp_name), --name too?
  FOREIGN KEY (hosp_name) REFERENCES Hospital (hosp_name) -- bc it belongs to hospital? or do i add hospital CHAR(60), prob not.. ..med dept belongs to one hospital
    ON DELETE CASCADE -- hospital has to have at least one dept (total func)..physician belongs to exactly one dept..nurse may work in one or many depts..has at least one physician, and at least one nurse... noted below.
);

------------------------------------------------
--  DDL Statements for table Physician
------------------------------------------------
CREATE TABLE Physician (
  PersonID VARCHAR(8) NOT NULL, -- make it same chars as id? ..... at least one phys in a med_dept
  med_special VARCHAR(20),
  years_as_phys int, -- whole number
  annual_salary_phys REAL, -- or FLOAT, IN CAD
  md_name VARCHAR(60) NOT NULL, 
  hosp_name VARCHAR(100) NOT NULL, -- from command..hosp_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (PersonID),
  FOREIGN KEY (PersonID) REFERENCES Person(id), -- good.
  FOREIGN KEY (md_name, hosp_name) REFERENCES Med_Dept (md_name, hosp_name)
    ON DELETE CASCADE -- Diagnoses AND ..Gives DRUGS and PRESCRIPTION to PATIENT..FOREIGN KEY (hospital) REFERENCES Hospital (id).. HOSPITAL has at least one MED_DEPT .. check..PHYSIAN belongs to exactly one MED_DEPT....from HOSPITAL..ADDED hosp_name, and FOREIGN KEY accordingly.
);

------------------------------------------------
--  DDL Statements for table Nurse
------------------------------------------------
CREATE TABLE Nurse (
  PersonID VARCHAR(8) NOT NULL, -- at least one nurse in a med_dept
  years_as_nurse int,
  annual_salary_nurse REAL,
  md_name VARCHAR(60) NOT NULL, 
  hosp_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (PersonID),
  FOREIGN KEY (PersonID) REFERENCES Person(id),
  FOREIGN KEY (md_name, hosp_name) REFERENCES Med_Dept (md_name, hosp_name)
    ON DELETE CASCADE -- NURSE may work in one or more MED_DEPT....from HOSPITAL..should be good like above..ADDED same as above
);

------------------------------------------------
--  DDL Statements for table Patient
------------------------------------------------
CREATE TABLE Patient ( --below nurse
  PersonID VARCHAR(8) NOT NULL, --  NurseID VARCHAR(8) NOT NULL, -- "under the care of one nurse"..PhysID VARCHAR(8) NOT NULL, -- "associated with one physician"
  insurance_type VARCHAR(12) NOT NULL, -- should be one or other...
  PRIMARY KEY (PersonID),
  CHECK (insurance_type = 'public' OR insurance_type = 'private' OR insurance_type = 'self-funded'),
  FOREIGN KEY (PersonID) REFERENCES Person (id) --  FOREIGN KEY (NurseID) REFERENCES Nurse (PersonID),..FOREIGN KEY (PhysID) REFERENCES Physician (PersonID)
    ON DELETE CASCADE
);

------------------------------------------------
--  DDL Statements for table Admission_Rec
------------------------------------------------
CREATE TABLE Admission_Rec (
  PatientID VARCHAR(8) NOT NULL, -- bc it refers to a PATIENT... PATIENT arrives to HOSPITAL, HOSPITAL creates ADMISSION_REC
  ad_date DATE NOT NULL, -- can i do this??
  priority VARCHAR(20),
  hosp_name VARCHAR(100), -- "HOSPITAL may admit many patients including none"
  PRIMARY KEY (PatientID, ad_date),
  CHECK (priority = 'immediate' OR priority = 'urgent' OR priority = 'standard' OR priority = 'non-urgent'),
  FOREIGN KEY (PatientID) REFERENCES Person (id),
  FOREIGN KEY (hosp_name) REFERENCES Hospital (hosp_name)
    ON DELETE CASCADE --immediate, urgent, standard, non-urgent..PATIENT arrives to a HOSPITAL, ADMISSION_REC is created, PATIENT is admitted to many HOSPITALS including null..HOSPITAL may admit many PATIENTS, including none
);

------------------------------------------------
--  DDL Statements for table Diagnosis
------------------------------------------------
CREATE TABLE Diagnosis (
  PatientID VARCHAR(8) NOT NULL, -- "PHYSICIAN makes diagnosis of PATIENT's condition"
  PhysID VARCHAR(8) NOT NULL,
  diagnosed_disease VARCHAR(60),
  diag_date DATE NOT NULL,
  prognosis VARCHAR(20), -- excellent, good, fair, poor, very poor
  PRIMARY KEY (PatientID, PhysID),
  Check (prognosis = 'excellent' OR prognosis = 'good' OR prognosis = 'fair' OR prognosis = 'poor' OR prognosis = 'very poor'),
  FOREIGN KEY (PatientID) REFERENCES Patient (PersonID),
  FOREIGN KEY (PhysID) REFERENCES Physician (PersonID)
    ON DELETE CASCADE -- PATIENT under the care of one NURSE..NURSE may care for one or many PATIENT..PHYSICIAN treats at least one PATIENT by providing a DIAGNOSIS..PATIENT may undergo a set of tests
);

------------------------------------------------
--  DDL Statements for table Med_Test
------------------------------------------------
CREATE TABLE Med_Test (
  PatientID VARCHAR(8) NOT NULL, -- "PATIENT may undergo a set of MED_TEST" "to confirm or treat a diagnosed_disease"
  num_id VARCHAR(25) NOT NULL, --"identified by a unique numeric identifier"
  test_name VARCHAR(60),
  fee_CAD REAL, -- each time a test is done, date and results are recorded. should that be separate? how?
  test_date DATE NOT NULL,
  results VARCHAR(500), -- enough for a summary, like Twitter.
  PRIMARY KEY (PatientID, num_id),
  FOREIGN KEY (PatientID) REFERENCES Patient (PersonID)
    ON DELETE CASCADE
);

------------------------------------------------
--  DDL Statements for table Drug
------------------------------------------------
CREATE TABLE Drug (
drug_code VARCHAR(8) NOT NULL, -- or int... just in case it has letters
generic_name VARCHAR(60),
category VARCHAR(50),
unit_cost REAL,
PRIMARY KEY (drug_code) -- dosage for intended PATIENT..drug may be prescribed to zero or many PATIENT
);

------------------------------------------------
--  DDL Statements for table Prescription
------------------------------------------------
CREATE TABLE Prescription (
  PhysID VARCHAR(8) NOT NULL,
  PatientID VARCHAR(8) NOT NULL, -- PHYSICIAN may provide PRESCRIPTION to PATIENT..associates prescribing PHYSICIAN to the intended PATIENT
  drug_date DATE NOT NULL,
  drug VARCHAR(100),
  dosage VARCHAR(100), -- could be int. chose varchar bc "take 2 daily"
  drug_code VARCHAR(8) NOT NULL,
  PRIMARY KEY (PhysID, PatientID, drug_code),
  FOREIGN KEY (PatientID) REFERENCES Patient (PersonID),
  FOREIGN KEY (PhysID) REFERENCES Physician (PersonID),
  FOREIGN KEY (drug_code) REFERENCES Drug (drug_code)
    ON DELETE CASCADE
);

------------------------------------------------
--  DDL Statements for table Nurse_Dept
------------------------------------------------
CREATE TABLE Nurse_Dept ( -- NURSE belongs to many MED_DEPT
  NurseID VARCHAR(8) NOT NULL,
  md_name VARCHAR(60) NOT NULL,
  hosp_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (NurseID, md_name, hosp_name),
  FOREIGN KEY (NurseID) REFERENCES Nurse (PersonID),
  FOREIGN KEY (hosp_name, md_name) REFERENCES Med_Dept (hosp_name, md_name)
    ON DELETE CASCADE
);