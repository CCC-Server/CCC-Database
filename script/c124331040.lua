--드래곤블러드 크리스탈 팽
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCountLimit(1,id)
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_RITUAL) end)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.sdtg)
	e3:SetOperation(s.sdop)
	c:RegisterEffect(e3)
end

function s.spcon(_,tp)
	return Duel.IsTurnPlayer(1-tp)
end

function s.tributefilter(c,e,tp)
	return c:IsSetCard(0xda3) and c:IsAbleToGrave()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.tributefilter,tp,LOCATION_DECK,0,1,c,e,tp)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,true) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local e0=Effect.CreateEffect(e:GetHandler())
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e0:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e0:SetTargetRange(1,0)
	e0:SetTarget(function(_e,_c) return _c:IsLocation(LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE) and not _c:IsType(TYPE_RITUAL) end)
	e0:SetReset(RESET_PHASE|PHASE_END,2)
	Duel.RegisterEffect(e0,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=Duel.SelectMatchingCard(tp,s.tributefilter,tp,LOCATION_DECK,0,1,1,e:GetHandler(),e,tp)
	if #rg==0 or Duel.SendtoGrave(rg,REASON_RELEASE+REASON_EFFECT)==0 then return end
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,true,true,POS_FACEUP)>0 then
		c:CompleteProcedure()   
	end
end
function s.filter(c)
	return c:IsSetCard(0xda3) and c:IsSpellTrap() and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_CHAINING)
	e2:SetOperation(s.aclimit1)
	e2:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e2,tp)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_CHAIN_NEGATED)
	e3:SetOperation(s.aclimit2)
	e3:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e3,tp)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetCode(EFFECT_CANNOT_ACTIVATE)
	e4:SetTargetRange(1,0)
	e4:SetCondition(function(e) return Duel.GetFlagEffect(e:GetHandlerPlayer(),id)>0 end)
	e4:SetValue(function(_,te) return te:IsHasType(EFFECT_TYPE_ACTIVATE) end)
	e4:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e4,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local sg=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
	if sg then
		Duel.SSet(tp,sg)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		if sg:IsQuickPlaySpell() then
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		elseif sg:IsTrap() then
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		end
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		sg:RegisterEffect(e1)
	end
end
function s.aclimit1(e,tp,eg,ep,ev,re,r,rp)
	if not (ep==tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsTrapEffect()) then return end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
end
function s.aclimit2(e,tp,eg,ep,ev,re,r,rp)
	if not (ep==tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsTrapEffect()) then return end
	Duel.ResetFlagEffect(tp,id)
end
function s.sdfilter(c,e,tp)
	return c:IsType(TYPE_RITUAL) and c:IsSetCard(0xda3) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,true,POS_FACEUP)
end

function s.sdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1 and c:IsAbleToHand() and Duel.IsExistingMatchingCard(s.sdfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.sdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)~=0 and c:IsLocation(LOCATION_HAND) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.sdfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,SUMMON_TYPE_RITUAL,tp,tp,true,true,POS_FACEUP)
		end
	end
end