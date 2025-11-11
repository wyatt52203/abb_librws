MODULE motion
    ! interrupt identifiers
    VAR intnum intno1;
    VAR intnum intno2;
    VAR intnum intno3;
    VAR intnum intno4;

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
        ! Enforce Y bounds [-500, 600]

        ! +750 height - change in safety config
        ! -250 height - soft, -350 safety config

        ! left side -500 safety config 
        ! software -450

        ! right side safety 550
        ! software 500

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
        CONNECT intno3 WITH emergency_stop_trap;
        ISignalDO MyContinueSignal, 1, intno3;

        IDelete intno4;
        CONNECT intno4 WITH reset_trap;
        ISignalDO MyEmergencyStopSignal, 1, intno4;

        ConfL \Off;
        go := FALSE;
        state := 0;

        WHILE TRUE DO
            ! Update Globals?
            ReadPos;

            ! Wait for persistent variable signal
            WaitUntil go;

            ! Set Motion Parameters
            AccSet acc, jrk \FinePointRamp:=dac;
            IF state == 0 THEN
                ! Set state to running while in motion
                state := 1;

                MoveL [[300, y, z], [0,1,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;

                ! Reset state to idle after motion completion
                state := 0;
            ENDIF

            ! Reset go to wait for another signal
            go := FALSE;

            
        ENDWHILE        

        ERROR
            TPWrite "ERRNO: " + ValToStr(ERRNO);
            ! TRYNEXT;
    ENDPROC

    TRAP emergency_trap
        StopMove;
        ClearPath;
        state := 3
    ENDTRAP

    TRAP pause_trap
        StopMove;
        StorePath;
        go := FALSE;
        state := 2;
        
        ! WaitUntil play;
        ! SetDO MyPauseSignal, 0;

        ! RestoPath;
        ! StartMove;
    ENDTRAP

    TRAP continue_trap
        ! StopMove;
        ! StorePath;
        
        ! WaitUntil play;
        ! SetDO MyPauseSignal, 0;

        RestoPath;
        StartMove;
        state := 1;
    ENDTRAP

    TRAP reset_trap
        StopMove;
        ClearPath;
        StartMove;
        MoveJ [[300, lft, upr], [0,1,0,0], [-1,-1,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], v400, fine, tool0;

        go := FALSE;
        SetDO MyResetSignal, 0;

        ExitCycle;
    ENDTRAP

    
    
ENDMODULE