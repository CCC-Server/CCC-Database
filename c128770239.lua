--Example Dual Dragon
local s,id=GetID()
function s.initial_effect(c)
	--듀얼 몬스터 취급 (①)
	Gemini.AddProcedure(c)

	--② 특수 소환 조건
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--③ 듀얼 상태에서 얻는 효과
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(Gemini.EffectStatusCondition)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(Gemini.EffectStatusCondition)
	e3:SetTarget(s.fustg)
	e3:SetOperation(s.fusop)
	c:RegisterEffect(e3)
end

--② 특수 소환 조건
function s.spfilter(c)
	return c:IsFaceup() and not (c:IsType(TYPE_FUSION) or c:IsType(TYPE_GEMINI)) and c:IsType(TYPE_EFFECT)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_MZONE,0,nil)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 or #g==0
end

--③-1 드래곤족/듀얼 몬스터 서치
function s.thfilter(c)
	return (c:IsRace(RACE_DRAGON) or c:IsType(TYPE_GEMINI)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--③-2 융합 소환
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFusionSummonable,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetFusionMaterial(tp)
	local g=Duel.SelectMatchingCard(tp,Card.IsFusionSummonable,tp,LOCATION_EXTRA,0,1,1,nil,mg)
	local tc=g:GetFirst()
	if tc then
		Duel.FusionSummon(tp,tc,nil,nil)
	end
end


