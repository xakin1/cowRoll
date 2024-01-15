defmodule CowRoll.InterpreterTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "errors on interpreter" do
    test "div should return an division by 0" do
      try do
        {:error, error} = Interpreter.eval_input("5/0")
        assert error == "Error: division by 0"
      rescue
        _ ->
          assert false
      end
    end

    test "div should return must be an integer" do
      try do
        {:error, error} = Interpreter.eval_input("5/true")
        assert error == "Error: divider must be an integer"
        {:error, error} = Interpreter.eval_input("5/'a'")
        assert error == "Error: divider must be an integer"
      rescue
        error ->
          IO.puts(error)
          assert false
      end
    end

    test "div should return parenthesis error" do
      try do
        {:error, error} = Interpreter.eval_input("5/(3+4")
        assert error == "Error: divider must be an integer"
      rescue
        error ->
          IO.puts(error)
          assert false
      end
    end

    test "div should return an error" do
      try do
        Interpreter.eval_input("5/((2)")
        assert false
      rescue
        _ ->
          assert true
      end
    end

    test "pow should return an (ArithmeticError) bad argument in arithmetic expression" do
      try do
        Interpreter.eval_input("2^-3")
        assert false
      rescue
        error ->
          assert error == %ArithmeticError{message: "bad argument in arithmetic expression"}
      end
    end
  end

  describe "tests ifs" do
    test "should return 6" do
      result = Interpreter.eval_input("if true then 2+4 end")

      assert result == 6
    end

    test "should return 0" do
      result = Interpreter.eval_input("if false then 2+4 else 0 end")

      assert result == 0
    end

    test "nested if should return 6" do
      result = Interpreter.eval_input("if true then if true then 2+4 else 3 end else 2 end")

      assert result == 6
    end

    test "nested else should return 1" do
      result = Interpreter.eval_input("if false then 2+4 else if false then 0 else 1 end end")

      assert result == 1
    end

    test "nested else with operation should return 1" do
      result = Interpreter.eval_input("
      if false then
        2+4
      else
        if false then
          0
        else
          2-1
        end
      end")

      assert result == 1
    end

    test "empty body should return fail" do
      try do
        Interpreter.eval_input("if true then else if false then 0 else 2-1 end")
        assert false
      rescue
        _ ->
          assert true
      end
    end

    test "test if with boolean operation" do
      result = Interpreter.eval_input("if (5 == 1) then true else false end")
      assert false == result
      result = Interpreter.eval_input("if (5 > 1) then true else false end")
      assert true == result
      result = Interpreter.eval_input("if (6*(5 - 5) > 1) then true else false end")
      assert false == result
    end

    test "false and false if_then_else statemen with conditions and nested if_then_else in the if and else" do
      result =
        Interpreter.eval_input(
          "if (4>7) == (true or false) then if true then 2 else 1 end else if false then 3+5 else 0 end end"
        )

      assert result == 0
    end

    test "false and true -> if_then_else statemen with conditions and nested if_then_else in the if and else" do
      result =
        Interpreter.eval_input(
          "if (4>7) == (true or false) then if true then 2 else 1 end else if true then 3+5 else 0 end end"
        )

      assert result == 8
    end

    test "true and false -> if_then_else statemen with conditions and nested if_then_else in the if and else" do
      result =
        Interpreter.eval_input(
          "if (4<7) == (true or false) then if true then 2 else 1 end else if false then 3+5 else 0 end end"
        )

      assert result == 2
    end

    test "true and true -> if_then_else statemen with conditions and nested if_then_else in the if and else" do
      result =
        Interpreter.eval_input(
          "if (4<7) == (true or false) then if false then 2 else 1 end else if false then 3+5 else 0 end end"
        )

      assert result == 1
    end
  end

  describe "test list of numbers" do
    test "empty array" do
      input = "[]"
      {:ok, token} = Parser.parse(input)

      assert token == {:list_of_number, :"$undefined"}
    end

    test "array with an element" do
      result = Interpreter.eval_input("[1]")
      assert result == [1]
    end

    test "array with two elements" do
      result = Interpreter.eval_input("[1,2]")
      assert result == [1, 2]
    end

    test "array with n elements" do
      result = Interpreter.eval_input("[1,2,3,3]")

      assert result == [1, 2, 3, 3]
    end
  end

  describe "test variables" do
    test "create a variable" do
      result = Interpreter.eval_input("x=6")
      assert result == 6
    end

    test "using  a variable without initializing" do
      try do
        Interpreter.eval_input("x = x + 6")
      catch
        error -> assert error == {:error, "Variable 'x' is not defined"}
      end
    end

    test "overwrite the value of a variable" do
      result = Interpreter.eval_input("x=6; x=7")
      assert result == 7
    end

    test "using vars in operations" do
      result = Interpreter.eval_input("
        x= 6; y = x + 2")
      assert result == 8
    end

    test "using vars in operations changing values" do
      result = Interpreter.eval_input("x= 6; y = x + 2; x = x +2; z = x+y")
      assert result == 16
    end

    test "using vars with strings" do
      result = Interpreter.eval_input("x= \"hola mundo\" ")
      assert result == "hola mundo"
    end
  end

  describe "test fors" do
    test "basic loop" do
      result = Interpreter.eval_input("
      y = 0;
      for x <- 1..3 do
        y = y + x
      end;
      y
      ")
      assert 6 == result
    end

    test "loop with variables" do
      result = Interpreter.eval_input("
      y = 0;
      begin = 3;
      finish = 6;
      for x <- begin..finish do
        y = y + x
      end;
      y
      ")
      assert 18 == result
    end

    test "loop with array" do
      result = Interpreter.eval_input("
      y = 0;
      for x <- [1, 2, 3, 4, 5] do
        y = y + x
      end;
      y
      ")
      assert 15 == result
    end

    test "loop with array in a var" do
      result = Interpreter.eval_input("
      y = 0;
      enum = [1, 2, 3, 4, 5];
      for x <- enum do
        y = y + x
      end;
      y
      ")
      assert 15 == result
    end
  end

  describe "Test strings" do
    test "basic string" do
      result = Interpreter.eval_input("\"hola mundo\"")
      assert result == "hola mundo"
    end

    test "concat string" do
      result = Interpreter.eval_input("\"hola \" +  \"mundo\"")
      assert result == "hola mundo"
    end

    test "concat n string" do
      result =
        Interpreter.eval_input("\"hola \" +  \"mundo\" +  \", mundo \" +  \"avanzado\" +  \"\"")

      assert result == "hola mundo, mundo avanzado"
    end
  end

  describe "dice" do
    test "returns a rolled dice" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6")
        assert is_integer(dice)

        assert dice > 0 and dice <= 6
      end
    end

    test "returns a rolled dice plus 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 +3")
        assert is_integer(dice)

        assert dice >= 4 and dice <= 9
      end
    end

    test "returns a rolled dice minus 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 - 3")
        assert is_integer(dice)
        assert dice >= -2 and dice <= 3
      end
    end

    test "returns a rolled dice multiply 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 * 3")
        assert is_integer(dice)
        assert dice >= 3 and dice <= 18
      end
    end

    test "returns a rolled dice div 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 / 3")

        assert is_integer(dice)
        assert dice >= 0 and dice <= 2
      end
    end
  end

  describe "plus" do
    test "simple plus" do
      result = Interpreter.eval_input("1+2")
      assert result == 1 + 2
    end

    test "plus with n operators" do
      result = Interpreter.eval_input("1+2 +3 +2+1")
      assert result == 1 + 2 + 3 + 2 + 1
    end

    test "plus with negatives" do
      result = Interpreter.eval_input("1+ (-3)")
      assert result == 1 + -3
    end

    test "plus with negatives and multiple factors" do
      result = Interpreter.eval_input("1 + (-2) + 4 ")
      assert result == 1 - 2 + 4
    end
  end

  describe "minus" do
    test "simple minus" do
      result = Interpreter.eval_input("1-2")
      assert result == 1 - 2
    end

    test "minus with n operators" do
      result = Interpreter.eval_input("1-2 -3 -2-1")
      assert result == 1 - 2 - 3 - 2 - 1
    end

    test "minus with negatives" do
      result = Interpreter.eval_input("1 - (-3)")
      assert result == 1 - -3
    end
  end

  describe "test math operation" do
    test "should return a negative" do
      try do
        result = Interpreter.eval_input("- 1d6")
        assert result < 0
      catch
        {:error, _} -> assert false
      end
    end

    test "plus and minus with multiples operators x - (y + z)" do
      result = Interpreter.eval_input("1 - (2 + 4) ")
      assert result == 1 - (2 + 4)
    end

    test "plus and minus with multiples operators x - y + z" do
      result = Interpreter.eval_input("1 - 2 + 4 ")
      assert result == 1 - 2 + 4
    end

    test "should do a rounding up and return 3" do
      try do
        result = Interpreter.eval_input("5//2")
        assert result == 3
      rescue
        _ ->
          assert false
      end
    end

    test "should do a pow and return 8" do
      try do
        result = Interpreter.eval_input("2^3")
        assert 8 == result
      catch
        {:error, _} -> assert false
      end
    end

    test "should do a mod and return 2" do
      try do
        result = Interpreter.eval_input("12%10")
        assert 2 == result
      catch
        {:error, _} -> assert false
      end
    end

    test "should do a mod with negative numbers and return -2" do
      try do
        result = Interpreter.eval_input("12%-10")
        assert -8 == result
      catch
        {:error, _} -> assert false
      end
    end

    test "can do a mod with a complex expresion" do
      try do
        for _ <- 1..100 do
          result = Interpreter.eval_input("12%(-1d6*(3+5))")
          assert result <= 0 and result >= -36
          result = Interpreter.eval_input("12%-1d6*(3+5)")
          assert result <= 0 and result >= -36
        end
      catch
        {:error, _} -> assert false
      end
    end

    test "should do a pow with a big exponential" do
      try do
        result = Interpreter.eval_input("9^9999")

        assert result ==
                 29_570_038_080_193_553_244_202_241_247_182_381_904_736_703_321_559_616_717_052_369_766_327_700_458_176_486_171_014_763_873_531_311_900_779_405_275_511_722_677_224_608_928_649_741_110_810_778_003_714_836_325_316_042_186_166_990_796_173_111_553_392_470_503_228_770_292_616_359_897_477_006_822_490_266_771_708_311_010_156_387_354_813_759_534_835_519_867_309_530_278_009_216_021_014_468_422_618_683_416_085_201_240_881_900_696_792_962_780_195_582_937_398_604_502_704_630_941_781_757_102_261_117_896_383_852_983_027_277_086_981_356_076_466_523_504_607_298_188_323_156_949_582_300_141_432_428_033_822_840_728_160_709_641_694_694_631_974_768_106_968_066_157_416_761_673_042_023_288_900_130_167_925_190_470_593_163_889_479_633_963_650_401_989_652_971_144_044_227_895_115_458_923_617_583_921_692_271_487_959_478_105_314_259_597_356_800_173_880_535_562_903_333_968_558_439_558_312_971_211_920_855_290_601_749_774_732_483_081_370_871_536_779_307_136_413_286_168_834_578_290_093_418_272_238_480_842_486_774_755_541_216_912_068_813_554_389_615_477_881_034_622_307_250_708_201_099_944_310_605_415_116_057_906_334_873_755_911_896_899_063_889_245_289_330_017_905_578_033_239_868_792_237_594_046_562_891_000_234_570_480_466_714_010_999_453_530_847_119_757_231_540_057_030_904_501_661_985_773_270_656_842_558_313_984_162_772_020_111_292_439_880_448_957_340_032_753_024_733_913_834_974_990_022_017_764_760_636_694_657_353_730_216_426_495_327_531_084_479_505_061_474_803_804_732_314_821_604_283_108_521_267_568_018_402_829_588_216_144_038_265_805_230_547_746_623_167_129_930_066_055_598_553_157_592_489_665_718_202_117_566_661_312_585_309_037_516_052_129_309_448_917_931_270_523_260_917_503_972_946_864_253_126_691_364_385_172_837_056_393_336_351_614_486_329_037_825_347_107_549_497_401_114_852_235_477_832_880_366_337_996_240_797_554_262_456_425_498_262_419_217_851_488_935_965_187_810_761_681_385_761_194_585_157_126_506_108_224_424_390_904_410_625_004_411_327_211_536_311_088_007_224_067_161_223_041_670_200_661_941_492_645_863_388_106_811_833_930_148_937_860_388_331_508_538_314_380_428_730_050_076_775_666_909_687_123_531_201_671_191_360_119_217_587_501_707_278_464_879_792_528_321_317_975_757_211_887_757_288_864_691_395_808_200_589_001_779_854_265_847_570_611_022_274_694_232_573_900_967_994_912_314_133_071_818_621_945_357_512_571_493_309_401_506_640_075_696_965_320_149_269_351_852_661_649_392_235_050_778_658_497_673_682_783_702_780_921_253_995_141_030_624_954_339_652_548_192_953_932_138_333_189_858_174_054_944_709_300_427_759_038_623_238_352_949_052_038_092_448_982_650_259_590_937_926_840_780_906_849_543_078_295_742_149_516_334_088_901_540_757_903_467_420_116_929_759_740_765_340_006_739_557_729_956_994_519_994_913_383_636_380_177_110_823_095_493_818_782_391_932_936_669_614_298_902_041_280_348_726_614_984_850_834_485_233_646_361_804_743_009_899_859_708_625_059_629_383_116_744_797_287_745_994_208_817_233_824_989_183_345_435_088_824_346_418_798_826_990_434_298_496_571_771_493_972_235_442_882_128_821_309_527_093_860_441_661_061_595_020_273_963_143_689_053_752_482_859_639_369_807_328_593_770_978_885_470_297_033_825_398_751_284_590_314_653_846_037_731_013_041_166_624_253_279_570_850_473_018_581_121_397_059_634_128_992_476_605_199_470_753_609_284_601_349_842_100_514_651_879_475_565_895_369_724_582_244_439_281_960_525_068_068_004_212_786_428_530_358_394_076_488_796_560_856_526_453_286_465_790_038_263_980_955_744_560_865_625_661_093_634_746_457_202_552_213_684_457_672_181_829_716_782_426_727_002_047_419_392_239_300_823_545_212_530_022_202_370_160_195_445_330_783_651_431_891_091_761_092_973_520_338_839_147_013_827_757_400_238_179_104_442_275_472_661_714_530_715_283_142_865_238_053_023_093_387_577_869_025_073_918_273_669_194_911_232_341_967_717_015_764_574_035_115_829_624_021_239_216_402_232_027_147_112_072_565_950_900_550_711_954_318_831_286_711_688_187_370_886_681_109_988_455_937_046_782_685_468_683_648_085_472_877_458_262_192_974_943_341_418_780_094_655_746_680_886_596_745_948_012_865_599_992_266_034_667_429_228_735_904_479_455_139_666_557_247_545_538_687_230_835_313_771_462_482_702_323_289_559_129_812_773_126_534_151_050_023_743_061_056_350_650_587_143_674_609_086_550_502_476_987_720_690_212_456_531_379_547_297_168_100_561_437_791_860_423_543_993_348_197_783_350_688_668_919_400_815_812_835_663_168_261_393_455_057_577_254_481_144_689_900_804_864_513_306_941_006_577_949_611_465_572_940_022_955_061_091_010_981_022_280_645_044_953_998_958_131_993_831_403_625_268_773_217_675_882_000_804_535_233_472_218_762_320_602_097_772_373_589_352_029_443_597_255_260_804_766_286_134_394_912_540_998_684_180_555_769_384_208_029_934_015_945_625_879_466_674_973_545_800_341_008_789_340_689_223_622_240_339_876_620_293_011_096_863_701_364_928_653_956_368_622_168_279_951_349_110_322_105_526_787_531_670_781_652_750_939_856_398_657_730_408_147_642_156_017_685_352_830_914_182_230_007_783_681_987_587_300_990_858_029_825_767_062_720_256_673_185_657_544_792_552_864_756_501_107_273_639_733_925_320_263_530_866_879_991_279_199_727_260_917_164_090_022_389_800_696_661_554_406_662_374_173_305_694_465_568_301_632_615_422_176_407_166_881_580_233_772_343_523_334_186_406_775_337_635_806_673_342_790_639_651_806_227_129_252_424_045_577_693_626_753_414_349_694_553_699_940_163_249_006_525_148_204_520_410_201_904_859_942_835_613_082_281_938_321_532_089_639_520_181_799_674_513_019_249_008_237_449_574_279_675_032_848_026_951_246_175_575_505_494_642_028_127_562_838_850_097_175_189_691_138_026_028_837_490_492_372_078_483_198_841_981_773_067_535_582_004_401_845_695_722_447_453_889_725_452_189_908_600_602_369_908_861_169_419_639_699_252_646_556_010_477_630_410_083_621_544_218_003_625_879_269_186_834_792_963_889_922_901_474_479_189_929_367_195_477_529_283_797_063_289_174_436_932_922_566_545_663_364_711_314_940_699_390_542_611_625_491_987_237_864_525_818_027_204_029_745_142_761_700_093_615_966_099_513_525_380_766_872_035_910_548_570_373_776_464_116_056_100_415_314_756_489_075_975_296_837_057_314_567_045_244_255_224_443_934_646_752_230_285_478_698_788_583_762_905_771_913_114_237_762_914_500_338_426_938_587_249_651_589_716_374_088_187_451_124_786_192_699_694_914_868_163_105_274_601_292_065_199_860_787_757_572_337_838_800_795_758_305_342_602_393_333_453_008_108_349_880_617_535_806_539_734_784_817_132_736_583_765_860_452_206_985_398_729_662_997_963_448_326_516_846_612_648_665_667_410_064_247_766_458_362_670_505_426_949_493_400_466_925_584_610_160_801_681_424_204_455_185_269_755_647_078_902_978_191_494_229_618_180_160_102_786_256_115_693_217_764_873_106_000_509_855_516_598_230_166_922_485_061_931_568_418_920_421_355_730_198_372_688_770_124_704_040_649_788_955_314_384_017_818_928_854_518_308_204_753_445_829_435_883_287_879_908_970_225_620_684_083_705_762_169_137_367_729_763_920_421_976_436_710_390_032_384_197_426_163_185_263_705_519_853_731_224_531_526_467_401_992_709_431_861_761_187_733_932_582_006_525_807_559_615_314_657_011_190_241_547_472_011_135_532_909_957_385_882_000_812_321_589_993_409_902_299_047_644_525_884_965_566_791_214_257_881_192_183_555_965_606_994_115_702_423_432_248_917_009_237_335_510_046_016_219_635_064_715_118_555_100_959_004_428_863_042_372_263_113_096_983_369_932_095_934_486_594_530_062_522_579_603_482_790_558_852_761_178_379_477_062_843_380_891_467_222_884_013_104_741_297_537_068_515_229_759_322_379_716_816_688_641_823_301_984_907_902_509_586_631_857_687_780_589_880_079_652_470_916_876_025_997_575_067_773_343_562_654_605_315_193_792_244_767_608_341_342_346_143_371_558_807_666_530_562_245_904_259_627_156_054_184_268_081_711_361_487_458_094_523_396_212_970_850_052_054_571_809_822_955_705_308_460_844_030_980_144_613_065_390_387_516_163_498_755_779_379_719_883_079_160_805_872_209_998_856_717_686_830_143_523_379_611_427_465_423_614_307_306_174_849_215_657_378_385_500_916_228_222_233_592_211_545_032_152_971_682_739_774_819_329_285_159_665_985_998_815_756_450_261_922_418_996_447_694_848_105_783_033_418_185_908_388_472_699_065_389_325_786_309_303_314_580_466_486_624_134_047_653_822_459_616_014_565_218_780_841_269_642_049_690_829_853_879_935_427_474_436_839_121_216_936_091_290_503_546_350_388_722_131_042_640_107_264_305_931_037_721_109_393_149_769_757_313_249_399_911_667_699_014_063_033_275_135_817_872_967_642_187_429_919_438_990_565_019_422_811_091_054_991_832_673_108_425_594_484_075_773_246_528_383_308_708_619_849_081_426_053_280_483_224_641_388_400_430_414_079_610_039_997_955_092_964_197_683_584_100_478_829_217_010_888_557_644_469_762_836_134_080_204_029_697_435_632_826_728_926_338_553_434_493_320_609_343_504_373_740_636_338_788_677_486_921_840_423_163_922_011_229_387_040_507_612_715_036_528_952_537_556_240_710_181_240_315_440_197_802_783_756_884_747_213_245_008_907_584_235_916_181_268_057_331_481_122_372_627_618_501_351_418_291_781_082_016_785_907_223_723_490_432_667_679_470_198_967_192_763_318_889_594_422_314_120_430_529_191_977_272_349_121_534_109_256_962_392_713_234_345_209_004_085_793_217_885_951_654_329_475_100_990_050_527_530_887_039_823_706_933_636_042_779_991_779_742_739_205_913_916_892_479_050_342_035_322_331_415_720_861_807_636_146_692_968_854_219_356_868_380_381_320_050_819_242_314_083_445_547_645_371_336_194_221_067_383_731_457_128_363_664_501_360_900_423_116_580_376_502_116_706_686_340_912_772_673_297_944_316_028_312_937_501_647_392_905_685_993_958_829_516_347_044_248_183_994_709_284_278_013_981_928_435_012_466_404_034_216_317_441_390_796_316_558_933_151_256_466_299_953_910_698_983_057_854_770_840_074_569_232_913_024_127_935_440_980_448_048_048_225_222_931_672_093_780_709_511_346_418_859_497_601_091_080_577_947_853_968_788_958_839_298_868_031_998_145_923_655_620_055_867_676_970_881_487_273_533_572_534_065_833_887_185_944_677_160_184_600_300_841_676_836_092_512_434_995_324_353_573_781_756_687_135_178_522_370_512_103_461_402_180_355_083_036_748_951_420_840_322_767_530_853_707_071_241_079_232_220_700_485_431_854_290_223_655_489_976_801_238_461_720_160_333_422_844_601_992_038_990_362_837_820_062_034_805_625_031_849_942_629_136_028_963_224_763_264_918_594_291_058_132_335_754_830_581_724_662_725_919_501_840_488_798_841_968_805_999_058_339_837_219_267_471_262_525_646_626_481_115_005_704_867_442_972_668_051_862_965_551_403_768_012_558_261_258_797_141_909_374_946_256_080_820_744_506_981_914_021_604_599_834_812_612_911_468_981_690_159_374_467_012_553_254_467_510_152_122_608_128_118_526_205_143_002_628_567_763_911_205_058_981_484_089_445_063_925_312_227_297_156_574_819_515_815_226_705_264_496_060_187_984_459_372_944_609_156_633_574_632_350_439_639_188_842_061_121_305_395_501_949_223_457_042_602_289_040_822_345_435_531_431_410_292_004_367_782_317_582_244_666_934_734_230_469_992_087_996_482_151_797_335_813_166_140_518_352_958_778_655_212_380_541_770_708_732_623_725_994_587_557_051_738_808_690_393_647_783_463_838_973_619_031_375_364_955_834_992_555_598_419_585_936_808_651_891_097_547_008_331_255_147_499_972_522_982_764_496_440_853_210_788_466_655_724_475_736_233_635_306_799_685_713_498_651_495_985_416_152_932_810_517_582_073_377_481_192_674_721_483_835_033_518_179_478_512_926_510_196_265_421_191_987_311_253_902_444_830_654_213_015_249_784_562_788_675_821_006_381_940_927_727_803_797_139_022_846_222_722_392_173_144_911_498_124_622_263_762_556_297_135_799_129_914_761_877_834_671_478_935_475_607_404_943_296_052_753_221_847_284_775_859_680_071_164_719_520_781_584_643_290_533_835_147_972_276_625_783_445_031_054_465_600_606_029_383_933_811_394_144_549_916_753_990_510_332_575_200_965_122_624_042_281_639_187_787_166_139_697_105_027_251_762_738_273_612_662_466_825_287_676_665_812_207_822_791_553_099_424_225_902_561_578_601_700_094_217_249_553_393_903_866_523_935_231_439_795_231_874_160_866_835_083_002_479_750_522_917_174_243_984_938_157_640_255_744_881_114_423_432_856_278_281_953_572_244_699_693_718_421_884_209_408_629_980_999_899_657_811_805_537_222_473_717_721_490_235_280_510_501_257_668_686_031_638_225_015_257_560_142_582_041_829_759_711_142_917_169_669_283_692_433_176_347_491_975_784_425_336_398_994_743_098_294_658_517_001_590_759_607_096_696_809_896_810_199_425_012_325_141_575_633_439_607_741_103_828_417_184_537_984_829_736_385_175_187_821_043_843_922_916_918_497_921_626_733_246_346_349_488_728_012_465_502_515_835_727_748_075_661_320_440_942_255_813_521_813_605_602_954_002_582_878_877_636_144_092_482_061_051_613_154_728_125_870_768_417_776_377_780_952_097_988_638_892_756_560_559_992_172_866_846_718_663_746_826_331_406_030_145_201_705_245_142_413_843_929_752_819_510_627_309_980_809_575_820_380_943_400_546_534_944_354_720_213_762_371_197_796_194_563_515_317_985_122_239_306_227_452_805_339_194_206_261_922_327_328_881_385_264_946_493_107_731_598_333_726_490_360_478_756_392_805_900_488_889
      catch
        {:error, _} -> assert false
      end
    end

    test "pow with exponent 0 should return 1" do
      try do
        result = Interpreter.eval_input("2^0")
        assert 1 == result
      rescue
        _ -> assert false
      end
    end

    test "pow with negative base should return -8" do
      try do
        result = Interpreter.eval_input("-2^3")
        assert -8 == result
      rescue
        _ -> assert false
      end
    end

    test "pow with a complex expresion in the exponent" do
      for _ <- 1..100 do
        try do
          result = Interpreter.eval_input("2^((1d6 +3) * 3)")
          assert result > 64
        rescue
          _ -> assert false
        end
      end
    end

    test "apply correctly order and ignore the space" do
      number = Interpreter.eval_input("18 \n + 6 / \s 3")

      assert is_integer(number)
      assert number == 20
    end

    test "apply correctly order" do
      number = Interpreter.eval_input("18 + 6 / 3")

      assert is_integer(number)
      assert number == 20
    end

    test "apply correctly parathesis" do
      number = Interpreter.eval_input("18 / ((3 + 6) * 2)")

      assert is_integer(number)
      assert number == 1
    end

    test "should apply correctly the negative" do
      number = Interpreter.eval_input("-18 / ((3 + 6) * 2)")

      assert is_integer(number)
      assert number == -1
    end

    test "should apply correctly the negative with parenthesis" do
      number = Interpreter.eval_input("(-(3 + 6) * 2)")

      assert is_integer(number)
      assert number == -18
    end

    test "should apply correctly the negative and return a positive number" do
      number = Interpreter.eval_input("-18 / -((3 + 6) * 2)")

      assert is_integer(number)
      assert number == 1
    end

    test "more should return true" do
      result = Interpreter.eval_input("3 > 2")
      assert true == result
    end

    test "more with expression should return true" do
      result = Interpreter.eval_input("3 + 9 > (2 - 1d6)")
      assert true == result
    end

    test "more_equal with expression should return true" do
      for _ <- 1..100 do
        result = Interpreter.eval_input("(4 + 1d6)  >= 5")
        assert true == result
      end
    end

    test "less should return true" do
      result = Interpreter.eval_input("3 < 2")
      assert false == result
    end

    test "less with expression should return true" do
      result = Interpreter.eval_input("3 + 9 <= (2 - 1d6)")
      assert false == result
    end

    test "less_equal with expression should return true" do
      for _ <- 1..100 do
        result = Interpreter.eval_input("5 <= (4 + 1d6)")
        assert true == result
      end
    end

    test "test equal" do
      result = Interpreter.eval_input("4 == 5")
      assert false == result
      result = Interpreter.eval_input("5 == 5")
      assert true == result
    end

    test "test and" do
      result = Interpreter.eval_input("false and false")
      assert false == result
      result = Interpreter.eval_input("false and true")
      assert false == result
      result = Interpreter.eval_input("true and false")
      assert false == result
      result = Interpreter.eval_input("true and true")
      assert true == result
    end

    test "test or" do
      result = Interpreter.eval_input("false or false")
      assert false == result
      result = Interpreter.eval_input("false or true")
      assert true == result
      result = Interpreter.eval_input("true or false")
      assert true == result
      result = Interpreter.eval_input("true or true")
      assert true == result
    end

    test "test not" do
      result = Interpreter.eval_input("not false")
      assert true == result
    end

    test "test not with operation" do
      result = Interpreter.eval_input("not (false or true)")
      assert false == result
    end

    test "test not equal" do
      result = Interpreter.eval_input("5 != 6")
      assert true == result

      result = Interpreter.eval_input("true != true")
      assert false == result

      result = Interpreter.eval_input("true != (5<6)")
      assert false == result
    end

    test "test plus with variables" do
      result = Interpreter.eval_input("x = 6;x + 5")
      assert 11 == result
    end
  end
end
