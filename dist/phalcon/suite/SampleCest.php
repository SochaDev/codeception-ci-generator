<?php
namespace TestPROJECT_CAMEL;

class SampleCest {

  public function sampleTest(\ActorPROJECT_CAMEL $I) {
    $I->assertEquals("Yay, it worked!", "Yay, it worked!");
  }

}
