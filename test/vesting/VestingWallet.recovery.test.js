const hre = require('hardhat');
const { ethers } = hre;
const { expect } = require('chai');
const { prepare, deployUpgradeable, performUpgrade } = require('../fixture');
const utils = require('../../scripts/utils');

const allocation = {
    start: utils.dateToTimestamp('2021-09-01T00:00:00Z'),
    cliff: utils.durationToSeconds('1 year'),
    duration: utils.durationToSeconds('4 years'),
};

describe('Vesting recovery', function () {
    prepare();

    for (const { contractName, constructorArgs } of [
        { contractName: 'VestingWallet' },
        { contractName: 'VestingWalletV1' },
        { contractName: 'VestingWalletV2', constructorArgs: Array(4).fill(ethers.constants.AddressZero) },
    ])
    describe(contractName, function () {
        beforeEach(async function () {
            allocation.beneficiary = this.accounts.user1.address;
            allocation.newBeneficiary = this.accounts.user2.address;
            allocation.owner = this.accounts.admin.address;

            this.vesting = await deployUpgradeable(
                hre,
                contractName,
                'uups',
                [allocation.beneficiary, allocation.owner, allocation.start, allocation.cliff, allocation.duration],
                { unsafeAllow: 'delegatecall', constructorArgs }
            );
        });

        describe('recover beneficiary', function () {
            beforeEach(async function () {
                await Promise.all([this.vesting.start(), this.vesting.cliff(), this.vesting.duration(), this.vesting.beneficiary(), this.vesting.owner()]).then(
                    ([start, cliff, duration, beneficiary, owner]) => {
                        expect(start).to.be.equal(allocation.start);
                        expect(cliff).to.be.equal(allocation.cliff);
                        expect(duration).to.be.equal(allocation.duration);
                        expect(beneficiary).to.be.equal(allocation.beneficiary);
                        expect(owner).to.be.equal(allocation.owner);
                    }
                );
            });

            it('perform upgrade', async function () {
                const implementation = await hre.upgrades.erc1967.getImplementationAddress(this.vesting.address);
                await performUpgrade(hre, this.vesting, 'VestingWalletRecoveryLight', {
                    call: { fn: 'changeOwnerAndUpgrade', args: [allocation.newBeneficiary, implementation] },
                    unsafeAllow: 'delegatecall'
                });
            });

            afterEach(async function () {
                await Promise.all([this.vesting.start(), this.vesting.cliff(), this.vesting.duration(), this.vesting.beneficiary(), this.vesting.owner()]).then(
                    ([start, cliff, duration, beneficiary, owner]) => {
                        expect(start).to.be.equal(allocation.start);
                        expect(cliff).to.be.equal(allocation.cliff);
                        expect(duration).to.be.equal(allocation.duration);
                        expect(beneficiary).to.be.equal(allocation.newBeneficiary);
                        expect(owner).to.be.equal(allocation.owner);
                    }
                );
            });
        });
    });
});
