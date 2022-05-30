//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

struct Spend {
    uint CPI;
    uint CPC;
    uint dailySpend;
}

struct Reward {
    uint userReward;
    uint publisherReward;
    uint brokerReward;
}

struct Engagement {
    bool click;
    bool validated;
    address owner;
    address referer;
    address broker;
    string token;
}

/*
 * Off Chain for now.
 *
struct Target {
    Language language;
    Gender gender;
    int ageLower;
    int ageUpper;
    string[] locations;
    string[] interests;
}

/*
enum MediaFormat{ SQUARE, SMARTPHONEBANNER, LEADERBOARD, WIDESKYSCRAPER, SKYSCRAPER, HALFPAGE, LANDSCAPE, PORTRAIT, BILLBOARD}
enum MediaType{ IMAGE, VIDEO }
enum Language{ ENGLISH, JAPANESE, CHINESE, SPANISH, FRENCH, GERMAN, ITALIAN }
enum Gender{ MALE, FEMALE}
enum Party{ USER, ADVERTISER, PUBLISHER, PLATFORM, BROKER }
*/
