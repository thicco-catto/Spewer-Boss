local Constants = {}

Constants.MOD = RegisterMod("Spewer Boss", 1)

Constants.SPEWER_BOSS_TYPE = Isaac.GetEntityTypeByName("Spewer")

Constants.SPEWER_BOSS_FORMS = {
    DEFAULT = 1,
    RED_PILLED = 2,
    WHITE_PILLED = 3,
}
Constants.SPEWER_BOSS_JUMP_COUNTDOWN = 20
Constants.SPEWER_BOSS_JUMP_VELOCITY = 4

--Default attack
Constants.RAINING_PROJECTILES_AREA = 155/2
Constants.RAINING_PROJECTILES_FRAMES = 40

--White attack
Constants.WHITE_ATTACK_DURATION = 40

return Constants