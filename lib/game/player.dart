import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

enum PlayerState { idle, walk }

class Player extends SpriteAnimationGroupComponent<PlayerState> with HasGameRef {
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _walkAnimation;
  
  Vector2 velocity = Vector2.zero();
  bool isMoving = false;
  bool isFlipped = false;

  Player({
    super.position,
    super.anchor = Anchor.center,
  }) : super(size: Vector2.all(32));

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    current = PlayerState.idle;
    return super.onLoad();
  }

  Future<void> _loadAnimations() async {
    // Assuming 6 frames for these soldier animations (standard for many asset packs)
    // If it's different, we can adjust later.
    final idleImage = await gameRef.images.load('player/Soldier_Idle.png');
    final walkImage = await gameRef.images.load('player/Soldier_Walk.png');

    // Trying to detect frame count based on image width if possible, 
    // but Flame's images.load doesn't expose width easily here without more steps.
    // We'll stick to a common default or 6 frames.
    
    _idleAnimation = SpriteAnimation.fromFrameData(
      idleImage,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2.all(100),
      ),
    );

    _walkAnimation = SpriteAnimation.fromFrameData(
      walkImage,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2.all(100),
      ),
    );

    animations = {
      PlayerState.idle: _idleAnimation,
      PlayerState.walk: _walkAnimation,
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update animation state based on movement
    if (velocity.length > 0) {
      current = PlayerState.walk;
      
      // Flip sprite based on direction
      if (velocity.x < 0 && !isFlipped) {
        flipHorizontallyAroundCenter();
        isFlipped = true;
      } else if (velocity.x > 0 && isFlipped) {
        flipHorizontallyAroundCenter();
        isFlipped = false;
      }
    } else {
      current = PlayerState.idle;
    }
  }
}
