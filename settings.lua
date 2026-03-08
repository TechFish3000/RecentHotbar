data:extend({
    {
        type = "bool-setting",
        name = "enable-mod",
        setting_type = "runtime-per-user",
        default_value = true
    },
    {
        type = "int-setting",
        name = "working-hotbar",
        setting_type = "runtime-per-user",
        default_value = 1,
        allowed_values = {1,2,3,4,5,6,7,8,9,10}
    },
    {
        type = "bool-setting",
        name = "do-items-in-hotbar",
        setting_type = "runtime-per-user",
        default_value = false
    },
    {
        type = "bool-setting",
        name = "do-ghosts-in-hotbar",
        setting_type = "runtime-per-user",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "sort-rl",
        setting_type = "runtime-per-user",
        default_value = false
    }
})
