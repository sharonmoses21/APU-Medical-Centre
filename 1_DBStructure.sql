-- Use master database to create a new database
USE master;
GO

-- Delete the old Database
DROP DATABASE IF EXISTS MedicalInfoSystem;
GO
-- Create the MedicalInfoSystem Database
CREATE DATABASE MedicalInfoSystem;
GO

-- Switch to the MedicalInfoSystem database
USE MedicalInfoSystem;
GO

-- Create Patient Table
CREATE TABLE Patient (
    PID INT PRIMARY KEY IDENTITY(1,1),
    PName NVARCHAR(100) NOT NULL,
    PPassportNumber NVARCHAR(50) NOT NULL,
    PPhone NVARCHAR(20) NOT NULL,
    PaymentCardNumber NVARCHAR(50) NOT NULL,
    PaymentCardPinCode NVARCHAR(50) NOT NULL,
    SystemUserID NVARCHAR(10) NOT NULL
);
GO

-- Create Staff Table
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY IDENTITY(1,1),
    SName NVARCHAR(100) NOT NULL,
    SPassportNumber NVARCHAR(50) NOT NULL,
    SPhone NVARCHAR(20),
    Position NVARCHAR(20) CHECK (Position IN ('Doctor', 'Nurse')),
    SystemUserID NVARCHAR(10) UNIQUE NOT NULL
);
GO

-- Create Staff View
CREATE VIEW StaffView AS
SELECT
	SName,
	SPassportNumber,
	SPhone,
	Position,
	SystemUserID
FROM Staff
WHERE SystemUserID = SYSTEM_USER
	OR SYSTEM_USER IN (SELECT SystemUserID FROM Patient);
GO

-- Create Medicine Table
CREATE TABLE Medicine (
    MID INT PRIMARY KEY IDENTITY(1,1),
    MName NVARCHAR(50) NOT NULL
);
GO

-- Create Prescription Table
CREATE TABLE Prescription (
    PresID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT FOREIGN KEY REFERENCES Patient(PID),
    DoctorID INT FOREIGN KEY REFERENCES Staff(StaffID),
	MedID INT FOREIGN KEY REFERENCES Medicine(MID),
    PresDateTime DATETIME NOT NULL
);
GO

-- Create Prescription View for staff to check complete prescription information
CREATE VIEW PrescriptionView AS
SELECT pres.PresID, pres.PresDateTime, p.PName, p.PPassportNumber, p.PPhone, s.SName, s.SPhone, med.MName FROM Prescription pres
LEFT JOIN Patient p ON pres.PatientID = p.PID
LEFT JOIN Staff s ON pres.DoctorID = s.StaffID
LEFT JOIN Medicine med ON pres.MedID = med.MID
GO

-- Create Prescription View for patients to check their prescription information
CREATE VIEW PatientPrescriptionView AS
SELECT pres.PresDateTime, p.PName, p.PPassportNumber, p.PPhone, s.SName, s.SPhone, med.MName FROM Prescription pres
LEFT JOIN Patient p ON pres.PatientID = p.PID
LEFT JOIN Staff s ON pres.DoctorID = s.StaffID
LEFT JOIN Medicine med ON pres.MedID = med.MID
WHERE p.SystemUserID = SYSTEM_USER