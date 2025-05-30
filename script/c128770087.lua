-- Fortune Lady Reverse (Quick-Play Spell)
local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Release 1 Fortune Lady to summon token and grant multi-attack
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	-- Grave: banish to boost level of FL monster by top deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.lv2tg)
	e2:SetOperation(s.lv2op)
	c:RegisterEffect(e2)
	-- Recover: when FL level changes, add this from GY/banished to hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ADJUST)
	e3:SetRange(LOCATION_GRAVE+LOCATION_REMOVED)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.recovcon)
	e3:SetTarget(s.recovtg)
	e3:SetOperation(s.recovop)
	c:RegisterEffect(e3)
end

-- e1 cost: release 1 FL monster
function s.costfilter(c)
	return c:IsSetCard(0x31) and c:IsMonster() and c:IsReleasable()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroup(tp,s.costfilter,1,nil) end
	local g=Duel.SelectReleaseGroup(tp,s.costfilter,1,1,nil)
	e:SetLabel(g:GetFirst():GetLevel())
	Duel.Release(g,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local lv=e:GetLabel()
	local token=Duel.CreateToken(tp, 128770088) -- assume token script id+1
	if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 레벨 지정 효과
		local e0=Effect.CreateEffect(e:GetHandler())
		e0:SetType(EFFECT_TYPE_SINGLE)
		e0:SetCode(EFFECT_CHANGE_LEVEL_FINAL)
		e0:SetValue(lv)
		e0:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e0)

		-- 릴리스/소재 제한
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_UNRELEASABLE_NONSUM)
		e1:SetProperty(EFFECT_FLAG_OATH)
		e1:SetTargetRange(LOCATION_MZONE,0)
		e1:SetTarget(function(e,c) return c==token end)
		e1:SetValue(1)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)

		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
		e2:SetValue(1)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		token:RegisterEffect(e2)
		local e3=e2:Clone()
		e3:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
		token:RegisterEffect(e3)
		local e4=e2:Clone()
		e4:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
		token:RegisterEffect(e4)

		-- 멀티 어택 부여
		local e5=Effect.CreateEffect(e:GetHandler())
		e5:SetType(EFFECT_TYPE_FIELD)
		e5:SetCode(EFFECT_ATTACK_ALL)
		e5:SetTarget(function(e,c) return c:IsSetCard(0x31) and c:IsMonster() end)
		e5:SetValue(1)
		e5:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e5,tp)
	end
end



-- e2: banish to adjust level
function s.lv2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingTarget(s.costfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.costfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.lv2op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)==0 then return end
	Duel.ConfirmDecktop(tp,1)
	local dc=Duel.GetDecktopGroup(tp,1):GetFirst()
	if dc:IsType(TYPE_MONSTER) then
		local lv=dc:GetLevel()
		local e1=Effect.CreateEffect(tc)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(lv)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
	Duel.ShuffleDeck(tp)
end

-- e3: recover when FL level changes
function s.recovfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x31) and c:GetFlagEffect(id)==0
end
function s.recovcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.recovfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.recovtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.recovop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():IsRelateToEffect(e) then
		Duel.SendtoHand(e:GetHandler(),nil,REASON_EFFECT)
	end
end