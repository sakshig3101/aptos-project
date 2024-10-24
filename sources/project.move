module MyModule::Crowdfunding {

    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event;

    /// Struct representing a crowdfunding project.
    struct Project has store, key {
        total_funds: u64,  // Total tokens raised for the project
        goal: u64,         // Funding goal of the project
        is_active: bool,   // Status of the project
        owner: address,    // Owner of the project
    }

    /// Event to log contributions
    struct ContributionEvent has drop, store {
        contributor: address,
        amount: u64,
        project_owner: address,
    }

    /// Function to create a new educational project with a funding goal.
    public fun create_project(owner: &signer, goal: u64) {
        assert!(goal > 0, "Funding goal must be greater than zero.");

        let owner_addr = signer::address_of(owner);
        let project = Project {
            total_funds: 0,
            goal,
            is_active: true,
            owner: owner_addr,
        };
        move_to(owner, project);
    }

    /// Function for users to support an educational project by contributing tokens.
    public fun contribute_to_project(contributor: &signer, project_owner: address, amount: u64) acquires Project {
        assert!(amount > 0, "Contribution must be greater than zero.");

        let project = borrow_global_mut<Project>(project_owner);
        assert!(project.is_active, "Project is no longer active.");

        // Withdraw contribution from the contributor
        let contribution = coin::withdraw<AptosCoin>(contributor, amount);
        // Deposit contribution to the project owner's account
        coin::deposit<AptosCoin>(project_owner, contribution);

        // Update the total funds raised
        project.total_funds += amount;

        // Emit contribution event
        let event = ContributionEvent {
            contributor: signer::address_of(contributor),
            amount,
            project_owner,
        };
        event::emit_event(event);
    }

    /// Function to mark a project as inactive after reaching its goal or after a deadline.
    public fun finalize_project(owner: &signer, project_owner: address) acquires Project {
        let project = borrow_global_mut<Project>(project_owner);
        assert!(project.owner == signer::address_of(owner), "Only the project owner can finalize it.");

        project.is_active = false;
    }
}
