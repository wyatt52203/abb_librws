MODULE motion
    ! interrupt identifiers
    VAR intnum intno1;
    VAR intnum intno2;
    VAR intnum intno3;
    VAR intnum intno4;

    ! variables for calculation
    VAR jointtarget jt;
    VAR robtarget current_pos;

    ! global params
    PERS num spd;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num x_read;
    PERS num y_read;
    PERS num z_read;
    PERS num x_target;
    PERS num y_target;
    PERS num z_target;

    PERS num state;
    ! STATE DEFINITION
    ! 0 = IDLE
    ! 1 = RUNNING
    ! 2 = PAUSED
    ! 3 = ABORTED
    
    PROC ReadPos()
        
        ! Wait for robot to fully stop
        ! WaitRob \ZeroSpeed;

        jt := CjointT();

        ! Calculate robtarget from jointtarget
        current_pos := CalcRobT(jt, tool0);

        x_read := current_pos.trans.x;
        y_read := current_pos.trans.y;
        z_read := current_pos.trans.z;

    ENDPROC

    PROC EnforceBounds(INOUT num x, INOUT num y, INOUT num z)
        ! Enforce Y bounds [-450, 450]

        ! +750 height in safety, 700 here
        ! -250 height - soft, -350 safety config

        ! left side -500 safety config 
        ! software -450

        ! right side safety 550
        ! software 450

        IF y > 450 THEN
            y := 450;
        ELSEIF y < -450 THEN
            y := -450;
        ENDIF

        ! Enforce Z bounds [10, 850]
        IF z > 700 THEN
            z := 700;
        ELSEIF z < -250 THEN
            z := -250;
        ENDIF

        IF x > 450 THEN
            x := 450;
        ELSEIF x < 250 THEN
            x := 250;
        ENDIF
    ENDPROC
    
    PROC main()

        IDelete intno1;
        CONNECT intno1 WITH pause_trap;
        ISignalDO MyPauseSignal, 1, intno1;

        IDelete intno2;
        CONNECT intno2 WITH reset_trap;
        ISignalDO MyResetSignal, 1, intno2;

        IDelete intno3;
        CONNECT intno3 WITH continue_trap;
        ISignalDO MyContinueSignal, 1, intno3;

        IDelete intno4;
        CONNECT intno4 WITH emergency_trap;
        ISignalDO MyEmergencyStopSignal, 1, intno4;

        ConfL \Off;
        go := FALSE;
        state := 0;
        x_target := 300;
        y_target := -450;
        z_target := 700;
        acc := 100;
        jrk := 100;
        dac := 100;
        spd := 800;
        speed := [800, 1000, 5000, 1000];

        WHILE TRUE DO
            ! Update Globals?
            ReadPos;

            ! Wait for persistent variable signal
            IF go THEN
                ! Set Motion Parameters
                AccSet acc, jrk \FinePointRamp:=dac;
                IF state = 0 THEN
                    ! Set state to running while in motion
                    state := 1;
                    EnforceBounds x_target, y_target, z_target;
                    MoveL [[x_target, y_target, z_target], [0,1,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
                    
                ! Reset go to wait for another signal
                go := FALSE;
            ENDIF

            ! If in running state
            IF state = 1 THEN
                ! Wait for robot to fully stop, set to idle
                WaitRob \ZeroSpeed;

                state := 0;
            
            ENDIF
            


            
        ENDWHILE        

        ERROR
            TPWrite "ERRNO: " + ValToStr(ERRNO);
            ! TRYNEXT;
    ENDPROC

    TRAP emergency_trap
        SetDO MyEmergencyStopSignal, 0;
        StopMove;
        ClearPath;
        state := 3;
    ENDTRAP

    TRAP pause_trap
        SetDO MyPauseSignal, 0;
        StopMove;
        StorePath;
        go := FALSE;
        state := 2;
    ENDTRAP

    TRAP continue_trap
        SetDO MyContinueSignal, 0;
        IF state = 2 THEN
            RestoPath;
            StartMove;
            state := 1;
        ENDIF
    ENDTRAP

    TRAP reset_trap
        SetDO MyResetSignal, 0;
        
        StopMove;
        ClearPath;
        StartMove;

        ExitCycle;
    ENDTRAP

    
    
ENDMODULE