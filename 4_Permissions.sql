-- Use the appropriate database
USE MedicalInfoSystem;
GO

-- Create roles for each type of user
CREATE ROLE Role_Patient;
CREATE ROLE Role_Nurse;
CREATE ROLE Role_Doctor;
GO

-- Grant SELECT on Patient table's specific columns to Role_Patient
GRANT SELECT ON Patient(SystemUserID, PName, PPassportNumber, PPhone, PaymentCardNumber, PaymentCardPinCode) TO Role_Patient;
GO

-- Grant UPDATE on Patient table's specific columns to Role_Patient
GRANT UPDATE ON Patient(PName, PPassportNumber, PPhone, PaymentCardNumber, PaymentCardPinCode) TO Role_Patient;
GO

-- Grant SELECT on Staff view's specific columns to Role_Patient
GRANT SELECT ON StaffView(SName, SPhone) TO Role_Patient;
GO

-- Grant permissions to Role_Patient to view their prescriptions via PatientPrescriptionView
GRANT SELECT ON PatientPrescriptionView TO Role_Patient;
GO

-- Create patient users and assign roles
CREATE USER P001 FOR LOGIN [P001];
EXEC sp_addrolemember 'Role_Patient', 'P001';
GO
CREATE USER P002 FOR LOGIN [P002];
EXEC sp_addrolemember 'Role_Patient', 'P002';
GO

-- Function to enforce row-level security for Patients
CREATE FUNCTION dbo.fn_securitypredicate_patient(@SystemUserID NVARCHAR(10))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS result
WHERE EXISTS (
    -- Check if a Patient is accessing their own data
    SELECT 1
    FROM dbo.Patient
    WHERE @SystemUserID = SYSTEM_USER
		OR SYSTEM_USER IN (SELECT SystemUserID FROM dbo.Staff)
);
GO

-- Security policy for Patient table
CREATE SECURITY POLICY PatientSecurityPolicy
ADD FILTER PREDICATE dbo.fn_securitypredicate_patient(SystemUserID) ON dbo.Patient
WITH (STATE = ON);
GO

-- Grant SELECT on all patient details except sensitive data to Role_Nurse
GRANT SELECT ON Patient(PID, PName, PPassportNumber, PPhone) TO Role_Nurse;
GO

-- Grant UPDATE on non-sensitive patient details to Role_Nurse
GRANT UPDATE ON Patient(PName, PPassportNumber, PPhone) TO Role_Nurse;
GO

-- Grant SELECT on Staff view to Role_Nurse
GRANT SELECT ON StaffView TO Role_Nurse;
GO

-- Grant SELECT on medicine to Role_Nurse
GRANT SELECT ON Medicine TO Role_Nurse;

-- Grant SELECT on prescriptions to Role_Nurse
GRANT SELECT ON PrescriptionView(PresDateTime, PName, PPassportNumber, PPhone, SName, SPhone, MName) TO Role_Nurse;
GO

-- Create nurse users and assign roles
CREATE USER N001 FOR LOGIN [N001];
EXEC sp_addrolemember 'Role_Nurse', 'N001';
GO
CREATE USER N002 FOR LOGIN [N002];
EXEC sp_addrolemember 'Role_Nurse', 'N002';
GO

-- Create stored procedure for staff to update their own data
CREATE PROCEDURE sp_UpdateStaff
    @SPassportNumber VARCHAR(50),
    @SPhone VARCHAR(20)
AS
BEGIN
    -- Enforce strict error checking
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Update only if SystemUserID matches SYSTEM_USER
        UPDATE Staff
        SET SPassportNumber = ISNULL(@SPassportNumber, SPassportNumber),
            SPhone = ISNULL(@SPhone, SPhone)
        WHERE SystemUserID = SYSTEM_USER;

        -- Commit the transaction
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of error
        ROLLBACK TRANSACTION;
        -- Re-throw the error for logging or further action
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Grant EXECUTE on the sp_UpdateStaff stored procedure to Role_Nurse
GRANT EXECUTE ON dbo.sp_UpdateStaff TO Role_Nurse;
GO

-- Grant SELECT on all patient details except sensitive data to Role_Doctor
GRANT SELECT ON Patient(PID, PName, PPassportNumber, PPhone) TO Role_Doctor;
GO

-- Grant SELECT on Staff view to Role_Doctor
GRANT SELECT ON StaffView TO Role_Doctor;
GO

-- Grant Role_Doctor permissions to add, update, and delete medicine and prescriptions
GRANT SELECT, INSERT, UPDATE, DELETE ON Prescription TO Role_Doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON Medicine TO Role_Doctor;
GRANT SELECT ON PrescriptionView TO Role_Doctor;
GO

-- Create User Accounts and Assign Roles
CREATE USER D001 FOR LOGIN [D001];
EXEC sp_addrolemember 'Role_Doctor', 'D001';

CREATE USER D002 FOR LOGIN [D002];
EXEC sp_addrolemember 'Role_Doctor', 'D002';
GO

-- Grant EXECUTE on the sp_UpdateStaff stored procedure to Role_Doctor
GRANT EXECUTE ON dbo.sp_UpdateStaff TO Role_Doctor;
GO

-- Stored Procedure for Doctors to manage prescriptions
CREATE PROCEDURE dbo.sp_ManagePrescription
    @PresID INT,
    @PatientID INT,
    @MedID INT,
    @Action NVARCHAR(10)  -- 'ADD', 'UPDATE', 'DELETE'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActualDoctorID INT;
    SELECT @ActualDoctorID = StaffID FROM dbo.Staff
		WHERE SystemUserID = SYSTEM_USER;

    IF @ActualDoctorID IS NULL
    BEGIN
        RAISERROR('Invalid doctor system user ID.', 16, 1);
        RETURN;
    END

    IF @Action = 'ADD'
    BEGIN
        INSERT INTO dbo.Prescription (PatientID, DoctorID, MedID, PresDateTime) 
        VALUES (@PatientID, @ActualDoctorID, @MedID, GETDATE());

        DECLARE @NewPresID INT = SCOPE_IDENTITY();
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
		UPDATE dbo.Prescription
		SET PatientID = ISNULL(@PatientID, PatientID), MedID = ISNULL(@MedID, MedID)
		WHERE PresID = @PresID AND DoctorID = @ActualDoctorID;
    END
    ELSE IF @Action = 'DELETE'
    BEGIN
		DELETE FROM dbo.Prescription
		WHERE PresID = @PresID AND DoctorID = @ActualDoctorID;
    END
END;
GO

-- Grant EXECUTE on the stored procedure to Role_Doctor
GRANT EXECUTE ON dbo.sp_ManagePrescription TO Role_Doctor;
GO