library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package module_config is
    
    constant c_number_of_bank           : integer := 4;
    constant c_number_of_lane           : integer := 32;

    constant c_lm00_SFF8024Identifier   : std_logic_vector(7 downto 0) := x"0d";
    constant c_lm01_CmisRevision        : std_logic_vector(7 downto 0) := x"53";
    constant c_lm02_mem_model           : std_logic_vector(7 downto 0) := b"0_1_0001_00";
    
    constant c_lm03_global_status       : std_logic_vector(7 downto 0) := b"UUUU_001_1";
    constant c_lm0407_flag_summary      : std_logic_vector(7 downto 0) := b"1111_XXXX";

    constant c_lm08_module_flag         : std_logic_vector(7 downto 0) := b"00_XXX_000";
    constant c_lm09_module_flag         : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm0a_module_flag         : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm0b_module_flag         : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm0d_custom_flag         : std_logic_vector(7 downto 0) := b"XXXX_XXXX";
    
    constant c_lm0e0f_TempMonValue      : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm1011_VccMonVoltage     : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm1213_Aux1MonValue      : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm1415_Aux2MonValue      : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm1617_Aux3MonValue      : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm1819_CustomMonValue    : std_logic_vector(7 downto 0) := b"XXXX_XXXX";

    constant c_lm1a_module_control      : std_logic_vector(7 downto 0) := b"0100_00XX";
    constant c_lm1b_MciSpeedConfig      : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm1d_custom_control      : std_logic_vector(7 downto 0) := b"XXXX_XXXX";
    constant c_lm1e_custom_control      : std_logic_vector(7 downto 0) := b"XXXX_XXXX";

    constant c_lm1f_module_mask         : std_logic_vector(7 downto 0) := b"00_XXX_000";
    constant c_lm20_module_mask         : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm21_module_mask         : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm22_module_mask         : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm24_custom_mask         : std_logic_vector(7 downto 0) := b"XXXX_XXXX";

    constant c_lm25_CdbStatus1          : std_logic_vector(7 downto 0) := b"0000_0000";
    constant c_lm26_CdbStatus2          : std_logic_vector(7 downto 0) := b"0000_0000";

    constant c_lm27_ModuleActiveFirmwareMajorRevision   : std_logic_vector(7 downto 0) := x"00";
    constant c_lm28_ModuleActiveFirmwareMinorRevision   : std_logic_vector(7 downto 0) := x"00";

    constant c_lm29_ModuleFaultCause    : std_logic_vector(7 downto 0) := x"00";
    constant c_lm2a_PasswordCmdResult   : std_logic_vector(7 downto 0) := b"0000_0000";

    constant c_lm38_CmisSmSupport       : std_logic_vector(7 downto 0) := x"01";
    constant c_lm39_ModuleFunctionType  : std_logic_vector(7 downto 0) := x"00";

    constant c_lm3c_SFF8024ModuleSubtype    : std_logic_vector(7 downto 0) := b"XXXX_0000";
    constant c_lm3c_SFF8024FiberFaceType    : std_logic_vector(7 downto 0) := b"XXXX_XX00";
    constant c_lm3c_LowPowerRestrictions    : std_logic_vector(7 downto 0) := b"0XXX_0000";
    constant 

    -- ============================================================================
    -- CMIS OPTIONAL PAGE FEATURE TOGGLEs
    -- Logic '1' = Implemented, Logic '0' = Not Implemented
    -- ============================================================================

    -- General Optional Pages
    constant c_03_user_nvram        : std_logic := '0'; -- User NV RAM
    constant c_04_laser_cap         : std_logic := '0'; -- Laser Capabilities

    -- Advanced Functional Pages
    constant c_12_tunable           : std_logic := '0'; -- Tunable Laser Control
    constant c_13_diag_ctrl         : std_logic := '0'; -- Perf Diag Control
    constant c_14_diag_res          : std_logic := '0'; -- Perf Diag Results
    constant c_15_timing            : std_logic := '0'; -- Timing Characteristics
    constant c_16_net_path          : std_logic := '0'; -- Network Path Control
    constant c_17_flags_masks       : std_logic := '0'; -- Flags/Masks
    constant c_18_cfg_ext           : std_logic := '0'; -- Config Extensions
    constant c_19_stat_ext          : std_logic := '0'; -- Status Extensions
    constant c_1c_norm_app          : std_logic := '0'; -- Normalized App Advertising
    constant c_1d_host_lane_sw      : std_logic := '0'; -- Host Lane Switching
    constant c_1e1f_custom          : std_logic := '0'; -- Custom Pages

    -- Diagnostics and Management
    constant c_202f_vdm             : std_logic := '0'; -- Versatile Diag Monitoring
    constant c_9f_cdb_local         : std_logic_vector := ('0','0'); -- CDB Command/Response
    constant c_a0af_cdb_ext         : std_logic_vector := ('0','0'); -- CDB Extended Payload
    constant c_b0ff_custom          : std_logic := '0'; -- Vendor Specific Pages

    -- Restricted for OIF
    constant c_05_cmis_ff           : std_logic := '0'; -- Restricted for OIF (CMIS-FF)
    constant c_0607_res_mod         : std_logic := '0'; -- Restricted for OIF (Resource Modules)
    constant c_080b_cmis_lt         : std_logic := '0'; -- Restricted for OIF (CMIS-LT)
    constant c_1a1b_res_mod         : std_logic := '0'; -- Restricted for OIF (Resource Modules)
    constant c_304f_c_cmis          : std_logic := '0'; -- Restricted for OIF (C-CMIS)
    constant c_505f_cmis_lt         : std_logic := '0'; -- Restricted for OIF (CMIS-LT)

    constant c_module_freq_hz       : real := 100_000_000.0;
    constant c_initial_bank_addr    : std_logic_vector(7 downto 0) := (others => '0');
    constant c_initial_page_addr    : std_logic_vector(7 downto 0) := (others => '0');
end package;

package body module_config is

end package body;