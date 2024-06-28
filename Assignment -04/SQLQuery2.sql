-- Creating the stored procedure to allocate subjects based on GPA and preferences
CREATE PROCEDURE AllocateSubjects
AS
BEGIN
    -- Declare variables
    DECLARE @StudentId VARCHAR(10);
    DECLARE @GPA FLOAT;
    DECLARE @SubjectId VARCHAR(10);
    DECLARE @Preference INT;
    DECLARE @RemainingSeats INT;

    -- Cursor to select students ordered by GPA in descending order
    DECLARE student_cursor CURSOR FOR
        SELECT StudentId, GPA
        FROM StudentDetails
        ORDER BY GPA DESC;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Preference = 1;
        WHILE @Preference <= 5
        BEGIN
            -- Get current subject based on preference
            SELECT @SubjectId = SubjectId
            FROM StudentPreference
            WHERE StudentId = @StudentId AND Preference = @Preference;

            -- Check remaining seats in the subject
            IF @SubjectId IS NOT NULL
            BEGIN
                SELECT @RemainingSeats = RemainingSeats
                FROM SubjectDetails
                WHERE SubjectId = @SubjectId;

                -- If seats are available, allocate subject and update remaining seats
                IF @RemainingSeats > 0
                BEGIN
                    INSERT INTO Allotments (SubjectId, StudentId) VALUES (@SubjectId, @StudentId);
                    UPDATE SubjectDetails
                    SET RemainingSeats = RemainingSeats - 1
                    WHERE SubjectId = @SubjectId;
                    BREAK; -- Exit inner loop if subject is allocated
                END
            END
            SET @Preference = @Preference + 1;
        END

        -- If no subject is allocated after checking all preferences, mark student as unallotted
        IF @Preference > 5
        BEGIN
            INSERT INTO UnallotedStudents (StudentId) VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END;
