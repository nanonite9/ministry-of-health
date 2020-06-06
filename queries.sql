--++++++++++++++++++++++++++++++++++++++++++++++
-- QUERIES
-- Filename: queries.sql
-- Author: nanonite9
-- Date: November 5, 2018
-- Description: This file creates SQL statements
-- for the Ministry of Health (MoH).
--++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------
--  connect to database
------------------------------------------------
connect to csdb;


-- all hospitals (name, city) with AnnualBudget > 3mil, descending order of AnnualBudget
SELECT HName, City
FROM Hospital
WHERE AnnualBudget > 3000000 order by AnnualBudget desc;

-- patients (FirstName, LastName, Gender, DateOfBirth) who are <= 40, from TO, and diagnosed with any cancer
SELECT DISTINCT FirstName, LastName, Gender, DateOfBirth
FROM Patient P, Person P1, Diagnose D
WHERE D.PatientID = P.PatientID and Disease LIKE ('%Cancer%') and P1.ID = D.PatientID and P1.City = 'Toronto' and (P1.DateOfBirth >= current date - 40 years);

-- avg salary for all physicians in each med specialty
SELECT AVG(Salary), Specialty 
FROM Physician 
GROUP BY Specialty;

-- avg salary for physicians in each med specialty working in TO, or HAM. Shown only for specialties with >= 5 physicians.
SELECT AVG(Salary), Specialty
FROM (SELECT * 
	  FROM Physician P, Hospital H, Department D
	  WHERE P.HName = H.HName and D.HName = H.HName and P.DName = D.DName and H.City IN ('Toronto', 'Hamilton')) 
GROUP BY Specialty HAVING COUNT(PhysicianID) >= 5;

-- avg salary for nurses, according to years of service, results show nurses by xp
SELECT AVG(Salary), YearsOfPractice
FROM Nurse
GROUP BY YearsOfPractice ORDER BY YearsOfPractice;

-- how many patients admitted to each hospital during these dates, results shown per hospital
SELECT HName, COUNT(A.PatientID) AS PatientCount
FROM Admission A
WHERE A.date BETWEEN '08/05/2017' and '08/10/2017'
GROUP BY HName;

-- which depts exist in all hospitals
SELECT DName
FROM Department
GROUP BY DName
HAVING COUNT(DName) = (SELECT COUNT(HName) FROM Hospital);
-- would inner join work? select d.dname from department as D inner join Hopsital as H on d.hname = h.hname group by d.dname having count(dname) = (select count(hname) from hospital);


-- which dept and hospital has largest # of staff working in that dept
SELECT D.HName, D.DName
FROM Department D
WHERE (D.HName, D.DName) in (SELECT NW.DName, P.DName
				 		   FROM Nurse_Work NW, Physician P
		  				   WHERE NW.HName = D.DName and NW.DName = P.DName
				  		   GROUP BY NW.DName, P.DName HAVING count(NurseID + PhysicianID) >= ALL (SELECT count(NurseID + PhysicianID)
				  													  	  	  FROM Nurse_Work NW, Physician P
				  															  WHERE NW.HName = P.HName and NW.DName = P.DName
				  													 		  GROUP BY NW.DName, P.DName ORDER BY count(NurseID + PhysicianID));

-- which depts are unique among all hospitals
SELECT DName
FROM Department D
GROUP BY DName
HAVING COUNT(DName) = 1;

-- all nurses who cared for <= 3 patients, in alphabetical order by last name
SELECT P1.LastName, P1.FirstName
FROM Person P1, Nurse N, Patient P
WHERE N.NurseID = P.NurseID and N.NurseID = P1.ID
GROUP BY P1.FirstName, P1.LastName HAVING COUNT(P.PatientID) < 3 ORDER BY P1.LastName;

-- all patients with poor prognosis and cared for by a nurse from above query
SELECT DISTINCT P.PatientID, D.Prognosis, P.NurseID
FROM Patient P, Diagnose D
WHERE P.PatientID = D.PatientID and D.Prognosis = 'poor' and P.NurseID IN(SELECT N.NurseID
																		  FROM Nurse N, Patient P1
																		  WHERE N.NurseID = P1.NurseID
																		  GROUP BY N.NurseID HAVING COUNT(N.NurseID) < 3);
-- added P.NurseID (select)

-- which date did the HGH have the largest # of patient admits
SELECT date, count(date) as PatientCount
FROM Admission
WHERE HName = 'Hamilton General Hospital'
GROUP BY date HAVING count(date) >= ALL (SELECT count(date)
										   FROM Admission
										   WHERE HName = 'Hamilton General Hospital' 
										   GROUP BY date);

-- alternate query for above
SELECT A.date, count(A.PatientID)
FROM Admission A, Hospital H
WHERE A.HName = 'Hamilton General Hospital' and A.HName = H.HName
GROUP BY A.date ORDER BY count(A.PatientID) DESC
FETCH FIRST 1 ROWS ONLY;


-- drug with largest sales revenue, and total sales amount
SELECT D.DrugCode, D.Name, COUNT(P.DrugCode), (COUNT(P.DrugCode) * D.UnitCost) as TotalSalesAmount
FROM Drug D, Prescription P
WHERE D.DrugCode = P.DrugCode
GROUP BY D.DrugCode, D.Name, D.UnitCost ORDER BY COUNT(P.DrugCode) DESC
FETCH FIRST 1 ROWS ONLY;

-- all patients diagnosed with diabetes but haven't taken a red blood cell test or lymphocytes test
SELECT P1.ID, P1.FirstName, P1.LastName, P1.Gender
FROM Person P1, Patient P, Diagnose D
WHERE P1.ID = P.PatientID and P.PatientID = D.PatientID and D.Disease = 'Diabetes' and NOT EXISTS (SELECT P.PatientID
									   															   FROM Patient P, Person P1, Take T, MedicalTest M
									   															   WHERE P.PatientID = T.PatientID and T.TestID = M.TestID and P.PatientID = P1.ID and M.Name = '%Red Blood Cell%' and M.Name = '%Lymphocytes%');
-- nor = neither or, so didnt take Red Blood Cell Test or Lymphocytes test

-- for each physician in the ICU at MUMC, return disease and prognosis of each of their patients (no dupes)
SELECT DISTINCT D.PhysicianID, D.Disease, D.Prognosis 
FROM Physician P, Diagnose D
WHERE P.PhysicianID = D.PhysicianID and D.PhysicianID IN (SELECT P.PhysicianID
														  FROM Physician P, Hospital H
														  WHERE P.DName = 'Intensive Care Unit' and H.HNAME = 'McMaster University Medical Centre' and H.HName = P.HName);

-- for each patients in above query, report patient id and total cost they spent in med tests, shown in decreasing order of total cost
SELECT P.PatientID, sum(M.Fee)
FROM Patient P, MedicalTest M, Take T
WHERE P.PatientID = T.PatientID and M.TestID = T.TestID and P.PatientID IN (SELECT D.PatientID
																		FROM Physician P, Diagnose D
																		WHERE P.PhysicianID = D.PhysicianID and D.PhysicianID in (SELECT P.PhysicianID
														  																		  FROM Physician P, Hospital H
														 																		  WHERE P.DName = 'Intensive Care Unit' and H.HNAME = 'McMaster University Medical Centre' and H.HName = P.HName) )
GROUP BY (P.PatientID);

-- for each patients in above the above query, report patient id and total cost they spent on drugs via scripts, shown in decreasing order of total cost
SELECT P.PatientID, sum(D.UnitCost)
FROM Patient P, Prescription Pr, Drug D
WHERE P.PatientID = Pr.PatientID and Pr.DrugCode = D.DrugCode and P.PatientID IN (SELECT D.PatientID
																			FROM Physician P, Diagnose D
																			WHERE P.PhysicianID = D.PhysicianID and D.PhysicianID in (SELECT P.PhysicianID
														  																			  FROM Physician P, Hospital H
														 																			  WHERE P.DName = 'Intensive Care Unit' and H.HNAME = 'McMaster University Medical Centre' and H.HName = P.HName))
GROUP BY (P.PatientID);

-- all patients admitted to exactly two hopsitals with urgent or standard admisions
SELECT P1.ID, P1.FirstName, P1.LastName
FROM Person P1, Admission A
WHERE P1.ID = A.PatientID and A.Category IN ('urgent', 'standard') 
GROUP BY P1.ID, P1.FirstName, P1.LastName, A.HName, A.Category HAVING COUNT(A.HNAME) = 2;
-- would put COUNT(DISTINCT A.HNAME) = 2 but it returned no results
-- DISTINCT would specify two different hospitals, but this shows the same hospital