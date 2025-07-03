<?php

for ($numBeers = 99; $numBeers >= 0; $numBeers--) {
    // Determine the correct pluralization for "bottle"
    $bottleStr = ($numBeers === 1) ? 'bottle' : 'bottles';

    // The core phrases for the song
    $beerOnWall = "$numBeers $bottleStr of beer on the wall";
    $beerPlain = "$numBeers $bottleStr of beer";
    $takeDown = "Take one down and pass it around";

    if ($numBeers > 1) {
        // More than one bottle
        echo "$beerOnWall, $beerPlain.\n";
        $nextNumBeers = $numBeers - 1;
        $nextBottleStr = ($nextNumBeers === 1) ? 'bottle' : 'bottles';
        echo "$takeDown, $nextNumBeers $nextBottleStr of beer on the wall.\n";
    } elseif ($numBeers === 1) {
        // Exactly one bottle
        echo "$beerOnWall, $beerPlain.\n";
        echo "$takeDown, no more bottles of beer on the wall.\n";
    } else {
        // No more bottles (numBeers is 0)
        echo "No more bottles of beer on the wall, no more bottles of beer.\n";
        echo "Go to the store and buy some more, 99 bottles of beer on the wall.\n";
    }

    echo "\n"; // Add a new line for separation between verses
}

?>
