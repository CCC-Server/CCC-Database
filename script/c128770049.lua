local s,id=GetID()
function s.initial_effect(c)
	--① 효과: 묘지에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE+LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

  -- ②: 싱크로 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1)) -- 효과 설명
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING) -- 체인 발생 시 발동
	e2:SetRange(LOCATION_MZONE) -- 필드 위에서 발동 가능
	e2:SetCountLimit(1,{id,1}) -- 한 턴에 한 번 발동 제한
	e2:SetCondition(s.syncon)
	e2:SetTarget(s.syntg)
	e2:SetOperation(s.synop)
	c:RegisterEffect(e2)

	--③ 효과: 필드에서 묘지로 보내졌을 때 발동
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.tncon)
	e3:SetTarget(s.tntg)
	e3:SetOperation(s.tnop)
	c:RegisterEffect(e3)
end

--① 효과
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToGraveAsCost,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGraveAsCost,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_SPELLCASTER) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsLevel(4) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end


function s.syncon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and not re:GetHandler():IsOnField() -- 상대가 필드 이외에서 효과를 발동했을 경우
end

function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(aux.FilterFaceupFunction(Card.IsType,TYPE_TUNER),tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_EXTRA,0,1,nil,0x754) -- "매지컬★시스터" 카드군의 싱크로 몬스터
			and Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_SYNCHRO)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.synop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.FilterFaceupFunction(Card.IsType,TYPE_TUNER),tp,LOCATION_MZONE,0,nil)
	if g:GetCount()==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
	local sg=g:Select(tp,1,1,nil) -- 싱크로 소재 선택 (튜너)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
	local mg=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,99,nil) -- 추가 싱크로 소재 선택
	sg:Merge(mg)

	local sc=Duel.SelectMatchingCard(tp,Card.IsSetCard,tp,LOCATION_EXTRA,0,1,1,nil,0x754):GetFirst()
	if sc then
		Duel.SynchroSummon(tp,sc,nil,sg)
	end
end

--③ 효과: 필드에서 묘지로 보내졌을 때 발동
function s.tncon(e,tp,eg,ep,ev,re,r,rp)
   local c=e:GetHandler()
   return c:IsPreviousLocation(LOCATION_MZONE) -- 이 카드가 필드에서 묘지로 보내졌는지 확인
end
function s.tntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.tnop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		-- 튜너로 취급
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_ADD_TYPE)
		e1:SetValue(TYPE_TUNER)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
