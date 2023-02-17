# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)


Assignee.create([{
                   'name': 'Assignee do not exist'
}])

Project.create([{
                  'name': 'Project do not exist'
}])

User.create([
              {
                'email': "admin@inspiregroup.io",
                'password': 'azertyu',
                'password_confirmation': 'azertyu'
              }
])
