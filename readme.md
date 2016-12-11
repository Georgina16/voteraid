# VoterAid

*Stop voter intimidation at the source.*

## What it does

**VoterAid** is a technology solution designed to address the threat of voter intimidation. We aim to accomplish the following:

- Register On-The-Ground Responders for Election Day
- Inform voters of their rights
- Report potential instances of voter suppression
- Respond to instances of voter suppression immediately
- Analyze reported incidents to influence policy

## Our Wishlist

Keep an eye out on the list of extra stuff we want to add here. You can see them on our [Projects Board](https://github.com/Voter-Aid/voteraid/projects/2).

## The Brains

For our tech stack, we are using:
- Ruby on Rails
- PostgreSQL
- Bootstrap
- Twilio REST API
- Heroku for Hosting

## Contributing

We welcome help from the community and we are open to pull requests. You can find our requested [features here](https://github.com/Voter-Aid/voteraid/projects/2). Feel free to contribute!

## Setup for MacOS
1. Install Ruby v2.3.0. We highly suggest that you do so using a version manager such as rbenv, like the example below

    ```
    brew install rbenv
    rbenv init
    rbenv install 2.3.0
    rbenv global 2.3.0
    ```

2. Install and start PostgreSQL

    ```
    brew install postgresql
    brew services start postgresql
    ```

3. Clone the repository and then change into the application's directory
    - If you are using https:

        ```
        git clone https://github.com/Voter-Aid/voteraid.git
        cd voteraid
        ```

    - If you are using ssh:

        ```
        git clone git@github.com:Voter-Aid/voteraid.git
        cd voteraid
        ```

4. Install bundler, which is the dependency manager for ruby, and then install the required dependencies for our application

    ```
    gem install bundler
    bundle install
    ```

5. Create and migrate the application database

    ```
    rails db:create
    rails db:migrate
    ```

6. Run!

    ```
    rails s
    ```

## License
This project is licensed under an MIT License. See the [LICENSE](LICENSE.txt) file for details.
