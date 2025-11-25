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
    PERS bool go;
    PERS num spd := 800;
    PERS num acc := 100;
    PERS num jrk := 100;
    PERS num dac := 100;
    PERS zonedata zone := [TRUE, 0, 0, 0, 0, 0, 0];
    PERS speeddata speed := [800, 1000, 5000, 1000];
    PERS num x_target := 300;
    PERS num y_target := -450;
    PERS num z_target := 700;
    PERS num x_read;
    PERS num y_read;
    PERS num z_read;

    PERS bool fsm_channels_live;

    PERS num state := 0;
    ! STATE DEFINITION
    ! 0 = IDLE
    ! 1 = RUNNING
    ! 2 = PAUSED
    ! 3 = ABORTED
    
    PERS bool motion_complete;

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
        ! Reset interrupts
        SetDO MyResetSignal, 0;
        SetDO MyEmergencyStopSignal, 0;
        SetDO MyPauseSignal, 0;
        SetDO MyContinueSignal, 0;

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
        
        udp_channel_live := TRUE;
        fsm_channels_live := FALSE;

        WHILE TRUE DO
            ! Update Globals from robot
            ReadPos;

            IF state = 0 THEN

                IF go THEN
                    ! Set state to running while in motion
                    go := FALSE;
                    state := 1;

                    ! Set Motion Parameters
                    AccSet acc, jrk \FinePointRamp:=dac;
                    EnforceBounds x_target, y_target, z_target;
                    
                    MoveL [[x_target, y_target, z_target], [0,1,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
                ENDIF
            
            ENDIF

            ! If in running state
            IF state = 1 THEN
                ! Wait for robot to fully stop, set to idle
                WaitRob \ZeroSpeed;

                motion_complete := TRUE;
                state := 0;
                
            ENDIF
            
            ! Nothing to do in states 2 (paused) and 3 (estopped)
            
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
        IF state <> 2 THEN    
            StopMove;
            StorePath;
            go := FALSE;
            state := 2;
        ENDIF
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
        state := 0; ! should happen anyways because of exitcycle, but to be sure

        ExitCycle;
    ENDTRAP

    
    
ENDMODULE