--Dual Dragon Summoner (듀얼 드래곤 서머너)
local s,id=GetID()
function s.initial_effect(c)
	--① 듀얼 몬스터 취급
	Gemini.AddProcedure(c)

	--② 드래곤족 듀얼 몬스터 1장을 릴리스하고 어드밴스 소환 가능
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SUMMON_PROC)
	e1:SetCondition(s.sumcon)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)

	--③-1 듀얼 상태 효과: 상대 필드 몬스터의 공격력 감소 및 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(Gemini.EffectStatusCondition)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	--③-2 듀얼 상태 효과: 덱 되돌리고 드로우
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(Gemini.EffectStatusCondition)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

--------------------------------------------
--② 드래곤족 듀얼 몬스터 릴리스 어드밴스 소환
--------------------------------------------
function s.relfilter(c)
	return c:IsReleasable() and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI)
end
function s.sumcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	return minc<=1 and Duel.CheckReleaseGroup(tp,s.relfilter,1,false,1,true,c,tp,nil,false,nil)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectReleaseGroup(tp,s.relfilter,1,1,false,true,true,c,tp,nil,false,nil)
	Duel.Release(g,REASON_COST)
end

--------------------------------------------
--③-1 상대 필드 몬스터 공격력 감소 및 파괴
--------------------------------------------
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local atk=c:GetAttack()
	if not c:IsRelateToEffect(e) or atk<=0 then return end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local dg=Group.CreateGroup()
	for tc in g:Iter() do
		local atk0=tc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		Duel.AdjustInstantly(tc)
		if tc:GetAttack()<=0 then dg:AddCard(tc) end
	end
	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end
end

--------------------------------------------
--③-2 묘지의 드래곤족 듀얼 몬스터를 덱으로 되돌리고 드로우
--------------------------------------------
function s.tdfilter(c)
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI) and c:IsAbleToDeck()
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,3,nil)
	if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		local og=Duel.GetOperatedGroup()
		if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then
			Duel.BreakEffect()
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end
