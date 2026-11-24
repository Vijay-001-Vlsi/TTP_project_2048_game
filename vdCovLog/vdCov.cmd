gui_set_pref_value -category {coveragesetting} -key {geninfodumping} -value 1
gui_exclusion -set_force true
gui_assert_mode -mode flat
gui_class_mode -mode hier
gui_excl_mgr_flat_list -on  0
gui_covdetail_select -id  CovDetail.1   -name   Line
verdiWindowWorkMode -win $_vdCoverage_1 -coverageAnalysis
gui_open_cov  -hier regression_cm/merged.vdb -testdir {} -test {regression_cm/merged/simv} -merge MergedTest -db_max_tests 10 -fsm transition
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} tb_top
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} tb_top.dut
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.dut.vga_contr   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top.dut.vga_contr  -column {} 
gui_covdetail_select -id  CovDetail.1   -name   Condition
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.dut.vga_contr  tb_top.dut.u_sva   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top.dut.u_sva  -column {} 
gui_covdetail_select -id  CovDetail.1   -name   Toggle
gui_covdetail_select -id  CovDetail.1   -name   Line
gui_covdetail_select -id  CovDetail.1   -name   Toggle
gui_list_select -id CovDetail.1 -list tgl { {uio_oe[7:0]}   }
gui_list_action -id  CovDetail.1 -list {tgl} {uio_oe[7:0]}
gui_list_select -id CovDetail.1 -list tgl { {uio_oe[7:0]}  {uio_out[7:0]}   }
gui_list_action -id  CovDetail.1 -list {tgl} {uio_out[7:0]}
gui_covdetail_select -id  CovDetail.1   -name   FSM
gui_covdetail_select -id  CovDetail.1   -name   Condition
gui_covdetail_select -id  CovDetail.1   -name   Branch
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.dut.u_sva  tb_top.dut.db   }
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} tb_top.dut.db
gui_list_expand -id CoverageTable.1   tb_top.dut.db
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top.dut.db  -column {} 
gui_list_action -id  CovDetail.1 -list {branch} Branch0.5  -column {Coverage} 
gui_list_select -id CovDetail.1 -list branch { Branch0.5   }
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.dut.db  tb_top.dut.db.deb   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top.dut.db.deb  -column {Line} 
gui_covdetail_select -id  CovDetail.1   -name   Condition
gui_covdetail_select -id  CovDetail.1   -name   Branch
gui_covtable_show -show  { Design Hierarchy } -id  CoverageTable.1  -test  MergedTest
gui_src_highlight_item -id CovSrc.1 -lfrom 37 -idxfrom 7 -fileIdFrom 0 -lto 38 -idxto 16 -fileIdTo 0 -selection { ns = ps;
        y = 1'b0} -selectionId 0 -replace 0
gui_src_highlight_item -id CovSrc.1 -lfrom 37 -idxfrom 5 -fileIdFrom 0 -lto 38 -idxto 17 -fileIdTo 0 -selection {   ns = ps;
        y = 1'b0;} -selectionId 0 -replace 0
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.dut.db.deb  tb_top.dut.u_sva   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top.dut.u_sva  -column {} 
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.dut.u_sva  tb_top.dut.vga_contr   }
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.dut.vga_contr  tb_top.dut.db.muxes   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top.dut.db.muxes  -column {} 
vdCovExit -noprompt
