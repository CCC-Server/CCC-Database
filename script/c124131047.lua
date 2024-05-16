--아르카나 포스 XVI-더 타워
local s,id=GetID()
function s.initial_effect(c)
	--"빛의 결계" 존재시 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	--Toss a coin and apply the appropriate effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_COIN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetTarget(s.cointg)
	e2:SetOperation(s.coinop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e4)
end
s.toss_coin=true
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,73206827),tp,LOCATION_FZONE,0,1,nil)
end
function s.cointg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_COIN,nil,0,tp,1)
end
function s.coinop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	s.arcanareg(c,Arcana.TossCoin(c,tp))
end
function s.arcanareg(c,coin)
	--Heads: 자신 필드의 몬스터의 공격력은 자신 묘지의 카드의 수 x 100 올린다.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetCondition(s.rdcon1)
	e1:SetValue(s.val)
	c:RegisterEffect(e1)
	--Tails: 자신의 엔드 페이즈에 발동한다. 이 카드 이외의 자신 필드의 카드를 전부 파괴한다. 
	local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_RELEASE+CATEGORY_DESTROY)
    e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetCondition(s.rdcon2)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	Arcana.RegisterCoinResult(c,coin)
end
function s.rdcon1(e,tp,eg,ep,ev,re,r,rp)
	return Arcana.GetCoinResult(e:GetHandler())==COIN_HEADS
end
function s.val(e,c)
    return Duel.GetMatchingGroupCount(aux.TRUE,c:GetControler(),LOCATION_GRAVE,0,nil)*100
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsRelateToEffect(e) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end
function s.rdcon2(e,tp,eg,ep,ev,re,r,rp)
	return Arcana.GetCoinResult(e:GetHandler())==COIN_TAILS and Duel.GetTurnPlayer()==tp
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,0,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,0,e:GetHandler())
	Duel.Destroy(g,REASON_EFFECT)
end